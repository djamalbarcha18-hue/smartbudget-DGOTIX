// SmartBudget — paypal-webhook (Supabase Edge Function, Deno).
//
// The only thing that grants/revokes a PayPal-backed entitlement. PayPal calls
// this server-to-server; we verify the event via PayPal's verify API, dedupe by
// event id, then apply it to that one subscription
// (supabase/subscription_lifecycle.sql), which sets the user's plan from all
// their subscriptions. The server stays the source of truth — the client never
// sets its own plan.
//
// Handled: BILLING.SUBSCRIPTION.* (created, activated, updated, re-activated,
// suspended, cancelled, expired, payment failed), PAYMENT.SALE.COMPLETED
// (renewals and recovered payments) and a full PAYMENT.SALE.REFUNDED or
// PAYMENT.SALE.REVERSED (chargeback).
//
// Deploy:  supabase functions deploy paypal-webhook --no-verify-jwt
// Secrets: supabase secrets set PAYPAL_CLIENT_ID=... PAYPAL_SECRET=... \
//            PAYPAL_API_URL=https://api-m.paypal.com  PAYPAL_WEBHOOK_ID=...
// Point the PayPal webhook (BILLING.SUBSCRIPTION.*) at this function's URL.
import { HttpError, serviceClient } from "../_shared/auth.ts";
import { markEventOnce, priceToPlan, unmarkEvent } from "../_shared/billing.ts";
import {
  paypalAccessToken,
  paypalSale,
  verifyPaypalWebhook,
} from "../_shared/paypal.ts";
import {
  applySubscriptionEvent,
  type ApplyOutcome,
  ENTITLING,
  paypalStatus,
  type SubStatus,
  userIdOrNull,
} from "../_shared/subscriptions.ts";
import { MAX_WEBHOOK_BYTES, readTextBody } from "../_shared/body.ts";

function ok(body: unknown = { ok: true }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

/** Status implied by the event type when the resource doesn't give one. */
const TYPE_STATUS: Record<string, SubStatus> = {
  "BILLING.SUBSCRIPTION.ACTIVATED": "active",
  "BILLING.SUBSCRIPTION.RE-ACTIVATED": "active",
  "BILLING.SUBSCRIPTION.SUSPENDED": "paused",
  "BILLING.SUBSCRIPTION.CANCELLED": "canceled",
  "BILLING.SUBSCRIPTION.EXPIRED": "canceled",
};

/** Headers PayPal signs every webhook with (all needed to verify it). */
const PAYPAL_SIGNATURE_HEADERS = [
  "paypal-auth-algo",
  "paypal-cert-url",
  "paypal-transmission-id",
  "paypal-transmission-sig",
  "paypal-transmission-time",
];

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // Cheap checks first: a request without PayPal's signature headers (or
    // before the webhook is configured) never reaches PayPal's API.
    const webhookId = (Deno.env.get("PAYPAL_WEBHOOK_ID") ?? "").trim();
    const signed = PAYPAL_SIGNATURE_HEADERS.every((h) => !!req.headers.get(h));
    if (!webhookId || !signed) {
      return new Response(JSON.stringify({ error: "bad_signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const raw = await readTextBody(req, MAX_WEBHOOK_BYTES);
    const event = JSON.parse(raw);

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
      return await apply(db, token, type, resource, eventAt);
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
  token: string,
  type: string,
  resource: Json,
  eventAt: string | null,
): Promise<Response> {
  if (type.startsWith("BILLING.SUBSCRIPTION.")) {
    const subscriptionId = String(resource?.id ?? "");
    if (!subscriptionId) return ok({ ignored: "no_subscription" });
    // A failed renewal payment: no access until a payment goes through
    // (PayPal retries it, then suspends the subscription).
    const status: SubStatus | null =
      type === "BILLING.SUBSCRIPTION.PAYMENT.FAILED"
        ? "past_due"
        : paypalStatus(resource?.status) ?? TYPE_STATUS[type] ?? null;
    if (!status) return ok({ ignored: type });
    const planId = String(resource?.plan_id ?? "");
    const mapped = planId
      ? await priceToPlan(db, planId, "paypal", true)
      : null;
    // The plan comes only from our own price map: a plan we don't sell grants
    // nothing (and doesn't take a paid plan away either).
    if (ENTITLING.has(status) && !mapped) return ok({ ignored: "unknown_plan" });
    return result(
      await applySubscriptionEvent(db, {
        provider: "paypal",
        subscriptionId,
        userId: userIdOrNull(resource?.custom_id),
        plan: mapped?.plan ?? null,
        period: mapped?.period ?? null,
        status,
        customerId: resource?.subscriber?.payer_id ?? null,
        periodEnd: resource?.billing_info?.next_billing_time ?? null,
        eventAt,
      }),
    );
  }

  if (type === "PAYMENT.SALE.COMPLETED") {
    // A subscription payment went through: a renewal, or a failed payment
    // recovered.
    const subscriptionId = String(resource?.billing_agreement_id ?? "");
    if (!subscriptionId) return ok({ ignored: "not_a_subscription" });
    return result(
      await applySubscriptionEvent(db, {
        provider: "paypal",
        subscriptionId,
        userId: null,
        plan: null,
        period: null,
        status: "active",
        eventAt,
        payment: true,
      }),
    );
  }

  if (type === "PAYMENT.SALE.REFUNDED" || type === "PAYMENT.SALE.REVERSED") {
    // REVERSED (a chargeback) carries the sale itself; REFUNDED carries the
    // refund, whose sale tells the subscription and whether it was in full.
    let subscriptionId = String(resource?.billing_agreement_id ?? "");
    if (type === "PAYMENT.SALE.REFUNDED") {
      const saleId = String(resource?.sale_id ?? "");
      if (!saleId) return ok({ ignored: "no_sale" });
      const sale = await paypalSale(token, saleId);
      const refunded = Number(resource?.amount?.total ?? NaN);
      if (!(refunded >= sale.total)) return ok({ ignored: "partial_refund" });
      subscriptionId = sale.subscriptionId ?? "";
    }
    if (!subscriptionId) return ok({ ignored: "not_a_subscription" });
    return result(
      await applySubscriptionEvent(db, {
        provider: "paypal",
        subscriptionId,
        userId: null,
        plan: null,
        period: null,
        status: "refunded",
        eventAt,
      }),
    );
  }

  return ok({ ignored: type });
}

function result(outcome: ApplyOutcome): Response {
  if (outcome === "applied") return ok();
  return ok({ ignored: outcome === "stale" ? "older_event" : outcome });
}
