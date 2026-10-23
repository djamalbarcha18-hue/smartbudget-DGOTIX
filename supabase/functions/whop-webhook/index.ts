// SmartBudget — whop-webhook (Supabase Edge Function, Deno).
//
// The ONLY thing that grants or revokes a Whop-paid entitlement. Whop calls
// this server-to-server; we verify the signature, dedupe by delivery id, then
// read the membership the event is about back from Whop's API and apply it
// to that one subscription (supabase/subscription_lifecycle.sql), which sets
// the user's plan from all their subscriptions. Reading it back means the
// stored state is always Whop's current one, whatever order the deliveries
// arrive in, and never data the event carried.
//
// Handled: membership.* (activated, updated — renewals, cancellations at
// period end —, deactivated), payment.succeeded / payment.failed, refund.*
// and dispute.* (the membership's state after them).
//
// Deploy:  supabase functions deploy whop-webhook --no-verify-jwt
// Secrets: supabase secrets set WHOP_WEBHOOK_SECRET=ws_... WHOP_API_KEY=...
// Point a Whop webhook (API version v1) at this function's URL.
import { HttpError, serviceClient } from "../_shared/auth.ts";
import { markEventOnce, priceToPlan, unmarkEvent } from "../_shared/billing.ts";
import {
  applySubscriptionEvent,
  type ApplyOutcome,
  ENTITLING,
  userIdOrNull,
} from "../_shared/subscriptions.ts";
import {
  fetchWhopMembership,
  membershipIdOf,
  verifyWhopSignature,
  whopStatus,
} from "../_shared/whop.ts";
import { MAX_WEBHOOK_BYTES, readTextBody } from "../_shared/body.ts";

const HANDLED = /^(membership|payment|refund|dispute)\./;

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return reply({ error: "method_not_allowed" }, 405);

  try {
    // Cheap checks first: no signature header, nothing is read.
    if (!req.headers.get("webhook-signature")) {
      return reply({ error: "bad_signature" }, 401);
    }
    const raw = await readTextBody(req, MAX_WEBHOOK_BYTES);
    const secret = (Deno.env.get("WHOP_WEBHOOK_SECRET") ?? "").trim();
    if (!(await verifyWhopSignature(raw, req.headers, secret))) {
      return reply({ error: "bad_signature" }, 401);
    }

    const evt = JSON.parse(raw);
    const type = String(evt?.type ?? "");
    // The delivery id stays the same on Whop's retries.
    const eventId = req.headers.get("webhook-id") ?? String(evt?.id ?? "");
    if (!HANDLED.test(type)) return reply({ ok: true, ignored: type });

    const db = serviceClient();
    // Idempotency: a replayed event is acknowledged but not re-applied.
    if (!(await markEventOnce(db, eventId, type, "whop"))) {
      return reply({ ok: true, duplicate: true });
    }
    try {
      return await apply(db, evt?.data ?? {});
    } catch (e) {
      // Not applied: forget the event so Whop's retry is processed.
      await unmarkEvent(db, eventId);
      throw e;
    }
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    return reply({ error: "server_error" }, status);
  }
});

// deno-lint-ignore no-explicit-any
type Json = any;

/** Applies the current state of the membership one verified event is about. */
async function apply(db: Json, data: Json): Promise<Response> {
  const membershipId = membershipIdOf(data);
  if (!membershipId) return reply({ ok: true, ignored: "no_membership" });
  const m = await fetchWhopMembership(membershipId);
  if (!m) return reply({ ok: true, ignored: "unknown_membership" });

  const state = whopStatus(m?.status);
  if (!state) return reply({ ok: true, ignored: "unknown_status" });
  const planId = String(m?.plan_id ?? "");
  const mapped = planId ? await priceToPlan(db, planId, "whop", true) : null;
  // The plan comes only from our own price map, never from the metadata the
  // checkout carried: a plan we don't sell grants nothing.
  if (ENTITLING.has(state.status) && !mapped) {
    return reply({ ok: true, ignored: "unknown_price" });
  }
  return result(
    await applySubscriptionEvent(db, {
      provider: "whop",
      subscriptionId: membershipId,
      userId: userIdOrNull(m?.metadata?.user_id),
      plan: mapped?.plan ?? null,
      period: mapped?.period ?? null,
      status: state.status,
      customerId: m?.member_id ?? m?.user_id ?? null,
      periodEnd: m?.current_period_end ?? null,
      cancelAtPeriodEnd: state.cancelAtPeriodEnd || m?.cancel_at_period_end === true,
      eventAt: m?.updated_at ?? null,
    }),
  );
}

function result(outcome: ApplyOutcome): Response {
  if (outcome === "applied") return reply({ ok: true });
  return reply({ ok: true, ignored: outcome === "stale" ? "older_event" : outcome });
}
