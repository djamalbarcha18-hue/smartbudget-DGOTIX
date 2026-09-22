// SmartBudget — create-checkout (Supabase Edge Function, Deno).
//
// Creates a provider checkout for a signed-in user and returns its URL. The
// frontend just opens that URL; entitlement is granted later by the webhook.
// Provider API keys live ONLY here (secrets), never in the frontend.
//
//   POST { plan: "basic"|"pro", period: "monthly"|"yearly" } -> { url }
//   | { error: "not_configured" | "unknown_price" | ... }
//
// Deploy:  supabase functions deploy create-checkout
// Secrets: supabase secrets set PADDLE_API_KEY=... \
//            PADDLE_API_URL=https://api.paddle.com   (sandbox: https://sandbox-api.paddle.com)
//          supabase secrets set CHECKOUT_SUCCESS_URL=https://<site>/#/plans
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { planToPrice } from "../_shared/billing.ts";
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
    if (plan === "free") {
      return jsonResponse({ error: "invalid_plan" }, 400, cors);
    }

    const apiKey = (Deno.env.get("PADDLE_API_KEY") ?? "").trim();
    const apiUrl = (Deno.env.get("PADDLE_API_URL") ?? "https://api.paddle.com")
      .replace(/\/+$/, "");
    if (!apiKey) return jsonResponse({ error: "not_configured" }, 503, cors);

    const db = serviceClient();
    const priceId = await planToPrice(db, plan, period);
    if (!priceId) return jsonResponse({ error: "unknown_price" }, 400, cors);

    const successUrl = Deno.env.get("CHECKOUT_SUCCESS_URL") ?? undefined;

    // Paddle Billing: create a transaction; its checkout.url is the hosted page.
    // custom_data rides through to the subscription, so the webhook can bind the
    // grant to this user. No secret ever reaches the browser.
    const res = await fetch(`${apiUrl}/transactions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        items: [{ price_id: priceId, quantity: 1 }],
        custom_data: { user_id: userId, plan, period },
        ...(successUrl
          ? { checkout: { url: successUrl } }
          : {}),
      }),
    });

    if (!res.ok) {
      return jsonResponse({ error: "provider_error" }, 502, cors);
    }
    const data = await res.json().catch(() => ({}));
    const url: string | undefined = data?.data?.checkout?.url;
    if (!url) return jsonResponse({ error: "no_checkout_url" }, 502, cors);
    return jsonResponse({ url }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
