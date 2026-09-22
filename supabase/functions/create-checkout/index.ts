// SmartBudget — create-checkout (Supabase Edge Function, Deno).
//
// Creates a provider checkout for a signed-in user and returns its URL. The
// frontend just opens that URL; entitlement is granted later by the webhook.
// Provider API keys live ONLY here (secrets), never in the frontend.
//
//   POST { plan: "basic"|"pro", period: "monthly"|"yearly",
//          provider?: "paddle"|"paypal" } -> { url }
//   | { error: "not_configured" | "unknown_price" | ... }
//
// Deploy:  supabase functions deploy create-checkout
// Secrets (Paddle): PADDLE_API_KEY, PADDLE_API_URL
// Secrets (PayPal): PAYPAL_CLIENT_ID, PAYPAL_SECRET, PAYPAL_API_URL
// Common:  CHECKOUT_SUCCESS_URL, CHECKOUT_CANCEL_URL
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { planToPrice } from "../_shared/billing.ts";
import {
  createPaypalSubscription,
  paypalAccessToken,
  paypalConfigured,
} from "../_shared/paypal.ts";
import { normalizePlan, type Plan } from "../_shared/quota.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await req.json().catch(() => ({}));
    const plan: Plan = normalizePlan(body?.plan);
    const period = body?.period === "yearly" ? "yearly" : "monthly";
    const provider = body?.provider === "paypal" ? "paypal" : "paddle";
    if (plan === "free") {
      return jsonResponse({ error: "invalid_plan" }, 400, cors);
    }

    const db = serviceClient();
    const successUrl = Deno.env.get("CHECKOUT_SUCCESS_URL") ?? undefined;
    const cancelUrl = Deno.env.get("CHECKOUT_CANCEL_URL") ?? successUrl;

    const url = provider === "paypal"
      ? await paypalCheckout(db, userId, plan, period, successUrl, cancelUrl)
      : await paddleCheckout(db, userId, plan, period, successUrl);

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

async function paddleCheckout(
  db: DB,
  userId: string,
  plan: Plan,
  period: "monthly" | "yearly",
  successUrl?: string,
): Promise<string | Response> {
  const cors = corsHeaders();
  const apiKey = (Deno.env.get("PADDLE_API_KEY") ?? "").trim();
  const apiUrl = (Deno.env.get("PADDLE_API_URL") ?? "https://api.paddle.com")
    .replace(/\/+$/, "");
  if (!apiKey) return jsonResponse({ error: "not_configured" }, 503, cors);

  const priceId = await planToPrice(db, plan, period, "paddle");
  if (!priceId) return jsonResponse({ error: "unknown_price" }, 400, cors);

  // Paddle Billing: create a transaction; its checkout.url is the hosted page.
  const res = await fetch(`${apiUrl}/transactions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      items: [{ price_id: priceId, quantity: 1 }],
      custom_data: { user_id: userId, plan, period },
      ...(successUrl ? { checkout: { url: successUrl } } : {}),
    }),
  });
  if (!res.ok) return jsonResponse({ error: "provider_error" }, 502, cors);
  const data = await res.json().catch(() => ({}));
  const url: string | undefined = data?.data?.checkout?.url;
  if (!url) return jsonResponse({ error: "no_checkout_url" }, 502, cors);
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
