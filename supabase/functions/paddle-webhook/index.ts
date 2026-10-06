// SmartBudget — paddle-webhook (Supabase Edge Function, Deno).
//
// The ONLY thing that grants or revokes a paid entitlement. Paddle calls this
// server-to-server; we verify the signature, dedupe by event id, then apply the
// event to that one subscription (supabase/subscription_lifecycle.sql), which
// sets the user's plan from all their subscriptions. The server stays the
// source of truth — the client never sets its own plan.
//
// Handled: subscription.* (created, activated, updated — renewals and plan
// changes —, past_due, paused, resumed, canceled), a full refund or chargeback
// (adjustment.*), and coupon redemptions (transaction.completed).
//
// Deploy:  supabase functions deploy paddle-webhook --no-verify-jwt
// Secrets: supabase secrets set PADDLE_WEBHOOK_SECRET=...
// Point the Paddle notification destination at this function's URL.
import { HttpError, serviceClient } from "../_shared/auth.ts";
import {
  markEventOnce,
  priceToPlan,
  unmarkEvent,
  verifyPaddleSignature,
} from "../_shared/billing.ts";
import {
  applySubscriptionEvent,
  type ApplyOutcome,
  ENTITLING,
  paddleStatus,
  userIdOrNull,
} from "../_shared/subscriptions.ts";

function ok(body: unknown = { ok: true }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const raw = await req.text();
    const secret = (Deno.env.get("PADDLE_WEBHOOK_SECRET") ?? "").trim();
    const valid = await verifyPaddleSignature(
      raw,
      req.headers.get("Paddle-Signature"),
      secret,
    );
    if (!valid) {
      return new Response(JSON.stringify({ error: "bad_signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const evt = JSON.parse(raw);
    const type = String(evt?.event_type ?? "");
    const eventId = String(evt?.event_id ?? "");
    const data = evt?.data ?? {};

    const db = serviceClient();
    // Idempotency: a replayed event is acknowledged but not re-applied.
    if (!(await markEventOnce(db, eventId, type))) return ok({ duplicate: true });

    try {
      return await apply(db, type, data, String(evt?.occurred_at ?? "") || null);
    } catch (e) {
      // Not applied: forget the event so Paddle's retry is processed.
      await unmarkEvent(db, eventId);
      throw e;
    }
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    return new Response(JSON.stringify({ error: "server_error" }), {
      status,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// deno-lint-ignore no-explicit-any
type Json = any;

/** Applies one verified, first-seen event. */
async function apply(
  db: Json,
  type: string,
  data: Json,
  eventAt: string | null,
): Promise<Response> {
  const custom = data?.custom_data ?? {};

  if (type.startsWith("subscription.")) {
    const subscriptionId = String(data?.id ?? "");
    const status = paddleStatus(data?.status);
    if (!subscriptionId) return ok({ ignored: "no_subscription" });
    if (!status) return ok({ ignored: "unknown_status" });
    const priceId = String(data?.items?.[0]?.price?.id ?? "");
    const mapped = priceId
      ? await priceToPlan(db, priceId, "paddle", true)
      : null;
    // The plan comes only from our own price map, never from data the
    // checkout carried: a price we don't sell grants nothing.
    if (ENTITLING.has(status) && !mapped) return ok({ ignored: "unknown_price" });
    return result(
      await applySubscriptionEvent(db, {
        provider: "paddle",
        subscriptionId,
        userId: userIdOrNull(custom?.user_id),
        plan: mapped?.plan ?? null,
        period: mapped?.period ?? null,
        status,
        customerId: data?.customer_id ?? null,
        periodEnd: data?.current_billing_period?.ends_at ?? null,
        cancelAtPeriodEnd: data?.scheduled_change?.action === "cancel",
        eventAt,
      }),
    );
  }

  if (type === "adjustment.created" || type === "adjustment.updated") {
    // A refund (once approved) or a chargeback of the whole payment takes the
    // subscription's access away until a new period is paid. Partial refunds
    // and credits change nothing.
    const action = String(data?.action ?? "");
    const subscriptionId = String(data?.subscription_id ?? "");
    if (action !== "refund" && action !== "chargeback") {
      return ok({ ignored: "adjustment_" + action });
    }
    if (!subscriptionId) return ok({ ignored: "no_subscription" });
    if (String(data?.status ?? "") !== "approved") {
      return ok({ ignored: "not_approved" });
    }
    if (action === "refund" && String(data?.type ?? "") !== "full") {
      return ok({ ignored: "partial_refund" });
    }
    return result(
      await applySubscriptionEvent(db, {
        provider: "paddle",
        subscriptionId,
        userId: null,
        plan: null,
        period: null,
        status: "refunded",
        eventAt,
      }),
    );
  }

  if (type === "transaction.completed") {
    // Record a coupon redemption if one rode along (best-effort).
    const userId = String(custom?.user_id ?? "");
    const code = String(custom?.coupon ?? "").trim().toUpperCase();
    if (userId && code) {
      try {
        await db.from("coupon_redemptions")
          .insert({ code, user_id: userId });
      } catch (_) { /* non-fatal */ }
    }
    return ok();
  }

  return ok({ ignored: type });
}

function result(outcome: ApplyOutcome): Response {
  if (outcome === "applied") return ok();
  return ok({ ignored: outcome === "stale" ? "older_event" : outcome });
}
