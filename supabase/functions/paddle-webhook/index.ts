// SmartBudget — paddle-webhook (Supabase Edge Function, Deno).
//
// The ONLY thing that grants or revokes a paid entitlement. Paddle calls this
// server-to-server; we verify the signature, dedupe by event id, then keep
// ai_entitlements + subscriptions in sync. The server stays the source of truth
// — the client never sets its own plan.
//
// Deploy:  supabase functions deploy paddle-webhook --no-verify-jwt
// Secrets: supabase secrets set PADDLE_WEBHOOK_SECRET=...
// Point the Paddle notification destination at this function's URL.
import { HttpError, serviceClient } from "../_shared/auth.ts";
import {
  eventOrder,
  markEventOnce,
  priceToPlan,
  setEntitlementPlan,
  unmarkEvent,
  upsertSubscription,
  verifyPaddleSignature,
} from "../_shared/billing.ts";
import type { Plan } from "../_shared/quota.ts";

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
  const userId = String(custom?.user_id ?? "");

  switch (type) {
    case "subscription.activated":
    case "subscription.created":
    case "subscription.updated":
    case "subscription.canceled": {
      if (!userId) return ok({ ignored: "no_user" });
      const status = String(data?.status ?? "");
      const priceId = String(data?.items?.[0]?.price?.id ?? "");
      const mapped = priceId
        ? await priceToPlan(db, priceId, "paddle", true)
        : null;
      const active = status === "active" || status === "trialing";
      // The plan comes only from our own price map, never from data the
      // checkout carried: a price we don't sell grants nothing.
      if (active && !mapped) return ok({ ignored: "unknown_price" });
      const order = await eventOrder(db, userId, eventAt);
      if (order.stale) return ok({ ignored: "older_event" });
      // Active/trialing ⇒ the paid plan; anything else (canceled, paused) ⇒ free.
      const plan: Plan = active && mapped ? mapped.plan : "free";
      const scheduled = data?.scheduled_change ?? null;

      await setEntitlementPlan(db, userId, plan);
      await upsertSubscription(db, {
        userId,
        provider: "paddle",
        customerId: data?.customer_id ?? null,
        subscriptionId: data?.id ?? null,
        plan,
        period: mapped?.period ?? (custom?.period ?? null),
        status,
        currentPeriodEnd: data?.current_billing_period?.ends_at ?? null,
        cancelAtPeriodEnd: scheduled?.action === "cancel",
        eventAt: order.tracked ? eventAt : null,
      });
      return ok();
    }

    case "transaction.completed": {
      // Record a coupon redemption if one rode along (best-effort).
      const code = String(custom?.coupon ?? "").trim().toUpperCase();
      if (userId && code) {
        try {
          await db.from("coupon_redemptions")
            .insert({ code, user_id: userId });
        } catch (_) { /* non-fatal */ }
      }
      return ok();
    }

    default:
      return ok({ ignored: type });
  }
}
