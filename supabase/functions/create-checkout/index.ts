// SmartBudget — create-checkout (Supabase Edge Function, Deno).
//
// Creates a provider checkout for a signed-in user and returns its URL. The
// frontend just opens that URL; entitlement is granted later by the webhook.
// Provider API keys live ONLY here (secrets), never in the frontend.
//
//   POST { plan: "pro" (Premium), period: "monthly"|"yearly",
//          provider?: "whop"|"paypal" } -> { url }
//   | { error: "not_configured" | "unknown_price" | "already_subscribed" | ... }
//
// Deploy:  supabase functions deploy create-checkout
// Secrets (Whop): WHOP_API_KEY, optionally WHOP_API_URL (sandbox) and
//   WHOP_COMPANY_ID (the biz_... account, when the key covers several)
// Secrets (PayPal): PAYPAL_CLIENT_ID, PAYPAL_SECRET, PAYPAL_API_URL
// Common:  CHECKOUT_SUCCESS_URL, CHECKOUT_CANCEL_URL
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { rateLimited } from "../_shared/usage.ts";
import { planToPrice } from "../_shared/billing.ts";
import { createWhopCheckout, whopConfigured } from "../_shared/whop.ts";
import {
  createPaypalSubscription,
  paypalAccessToken,
  paypalConfigured,
} from "../_shared/paypal.ts";
import { normalizePlan, type Plan } from "../_shared/quota.ts";
import { MAX_SMALL_BODY_BYTES, readJsonBody } from "../_shared/body.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await readJsonBody(req, MAX_SMALL_BODY_BYTES);
    // One paid plan, Premium ("pro"); BASIC was merged into it.
    const asked: Plan = normalizePlan(body?.plan);
    const plan: Plan = asked === "basic" ? "pro" : asked;
    const period = body?.period === "yearly" ? "yearly" : "monthly";
    const provider = body?.provider === "paypal" ? "paypal" : "whop";
    if (plan === "free") {
      return jsonResponse({ error: "invalid_plan" }, 400, cors);
    }

    const db = serviceClient();
    if (await rateLimited(db, userId, "checkout")) {
      return jsonResponse({ error: "rate_limited" }, 429, cors);
    }
    // One subscription at a time: a second one would be billed alongside the
    // first. Someone already subscribed changes or cancels from Manage; a new
    // plan can be bought once the current one is set to end.
    const { data: live, error: liveError } = await db
      .from("billing_subscriptions")
      .select("status, cancel_at_period_end")
      .eq("user_id", userId)
      .in("status", ["active", "trialing", "past_due", "paused"]);
    if (liveError) return jsonResponse({ error: "not_configured" }, 503, cors);
    const blocking = (live ?? []).some((s: { status: string; cancel_at_period_end: boolean }) =>
      !((s.status === "active" || s.status === "trialing") && s.cancel_at_period_end)
    );
    if (blocking) return jsonResponse({ error: "already_subscribed" }, 409, cors);

    const successUrl = Deno.env.get("CHECKOUT_SUCCESS_URL") ?? undefined;
    const cancelUrl = Deno.env.get("CHECKOUT_CANCEL_URL") ?? successUrl;

    const url = provider === "paypal"
      ? await paypalCheckout(db, userId, plan, period, successUrl, cancelUrl)
      : await whopCheckout(db, userId, plan, period, successUrl);

    if (typeof url !== "string") return url; // an error Response
    return jsonResponse({ url }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});

// deno-lint-ignore no-explicit-any
type DB = any;

async function whopCheckout(
  db: DB,
  userId: string,
  plan: Plan,
  period: "monthly" | "yearly",
  successUrl?: string,
): Promise<string | Response> {
  const cors = corsHeaders();
  if (!whopConfigured()) {
    return jsonResponse({ error: "not_configured" }, 503, cors);
  }
  const planId = await planToPrice(db, plan, period, "whop");
  if (!planId) return jsonResponse({ error: "unknown_price" }, 400, cors);

  // A checkout configuration for the Whop plan: its metadata is copied onto
  // the membership, so the webhook knows whose it is.
  const url = await createWhopCheckout(
    planId,
    { user_id: userId, plan, period },
    successUrl,
  );
  if (!url) return jsonResponse({ error: "provider_error" }, 502, cors);
  return url;
}

async function paypalCheckout(
  db: DB,
  userId: string,
  plan: Plan,
  period: "monthly" | "yearly",
  successUrl?: string,
  cancelUrl?: string,
): Promise<string | Response> {
  const cors = corsHeaders();
  if (!paypalConfigured()) {
    return jsonResponse({ error: "not_configured" }, 503, cors);
  }
  const planId = await planToPrice(db, plan, period, "paypal");
  if (!planId) return jsonResponse({ error: "unknown_price" }, 400, cors);

  const token = await paypalAccessToken();
  const url = await createPaypalSubscription(
    token,
    planId,
    userId,
    successUrl,
    cancelUrl,
  );
  if (!url) return jsonResponse({ error: "no_checkout_url" }, 502, cors);
  return url;
}
