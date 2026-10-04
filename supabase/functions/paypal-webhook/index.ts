// SmartBudget — paypal-webhook (Supabase Edge Function, Deno).
//
// The only thing that grants/revokes a PayPal-backed entitlement. PayPal calls
// this server-to-server; we verify the event via PayPal's verify API, dedupe by
// event id, then keep ai_entitlements + subscriptions in sync. The server stays
// the source of truth — the client never sets its own plan.
//
// Deploy:  supabase functions deploy paypal-webhook --no-verify-jwt
// Secrets: supabase secrets set PAYPAL_CLIENT_ID=... PAYPAL_SECRET=... \
//            PAYPAL_API_URL=https://api-m.paypal.com  PAYPAL_WEBHOOK_ID=...
// Point the PayPal webhook (BILLING.SUBSCRIPTION.*) at this function's URL.
import { HttpError, serviceClient } from "../_shared/auth.ts";
import {
  eventOrder,
  markEventOnce,
  priceToPlan,
  setEntitlementPlan,
  unmarkEvent,
  upsertSubscription,
} from "../_shared/billing.ts";
import { paypalAccessToken, verifyPaypalWebhook } from "../_shared/paypal.ts";
import type { Plan } from "../_shared/quota.ts";

function ok(body: unknown = { ok: true }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

const REVOKE = new Set<string>([
  "BILLING.SUBSCRIPTION.CANCELLED",
  "BILLING.SUBSCRIPTION.EXPIRED",
  "BILLING.SUBSCRIPTION.SUSPENDED",
]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const raw = await req.text();
    const event = JSON.parse(raw);
    const webhookId = (Deno.env.get("PAYPAL_WEBHOOK_ID") ?? "").trim();

    // Verify with PayPal before trusting anything in the body.
    const token = await paypalAccessToken();
    const valid = await verifyPaypalWebhook(
      token,
      req.headers,
      webhookId,
      event,
    );
    if (!valid) {
      return new Response(JSON.stringify({ error: "bad_signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const type = String(event?.event_type ?? "");
    const eventId = String(event?.id ?? "");
    const resource = event?.resource ?? {};

    const db = serviceClient();
    if (!(await markEventOnce(db, eventId, type, "paypal"))) {
      return ok({ duplicate: true });
    }
    try {
      const eventAt = String(event?.create_time ?? "") || null;
      return await apply(db, type, resource, eventAt);
    } catch (e) {
      // Not applied: forget the event so PayPal's retry is processed.
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
  resource: Json,
  eventAt: string | null,
): Promise<Response> {
  const userId = String(resource?.custom_id ?? "");
  if (!userId) return ok({ ignored: "no_user" });

  const isActivate = type === "BILLING.SUBSCRIPTION.ACTIVATED" ||
    (type === "BILLING.SUBSCRIPTION.UPDATED" &&
      String(resource?.status ?? "").toUpperCase() === "ACTIVE");
  const isRevoke = REVOKE.has(type);
  if (!isActivate && !isRevoke) return ok({ ignored: type });

  const planId = String(resource?.plan_id ?? "");
  const mapped = planId
    ? await priceToPlan(db, planId, "paypal", true)
    : null;
  // The plan comes only from our own price map: a plan we don't sell grants
  // nothing (and doesn't take a paid plan away either).
  if (isActivate && !mapped) return ok({ ignored: "unknown_plan" });
  const order = await eventOrder(db, userId, eventAt);
  if (order.stale) return ok({ ignored: "older_event" });
  const plan: Plan = isActivate && mapped ? mapped.plan : "free";

  await setEntitlementPlan(db, userId, plan);
  await upsertSubscription(db, {
    userId,
    provider: "paypal",
    subscriptionId: resource?.id ?? null,
    plan,
    period: mapped?.period ?? null,
    status: String(resource?.status ?? "").toLowerCase() || null,
    currentPeriodEnd: resource?.billing_info?.next_billing_time ?? null,
    cancelAtPeriodEnd: isRevoke,
    eventAt: order.tracked ? eventAt : null,
  });
  return ok();
}
