// SmartBudget — manage-subscription (Supabase Edge Function, Deno).
//
// Returns a URL where the signed-in user can manage or cancel their current
// subscription (the provider's own hosted portal). No secret reaches the
// browser — the client just opens the URL.
//
//   POST -> { url } | { error: "no_subscription" | "not_available" | ... }
//
// Deploy:  supabase functions deploy manage-subscription
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { rateLimited } from "../_shared/usage.ts";
import { fetchWhopMembership, whopConfigured } from "../_shared/whop.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const db = serviceClient();
    if (await rateLimited(db, userId, "manage")) {
      return jsonResponse({ error: "rate_limited" }, 429, cors);
    }
    const { data: sub } = await db.from("subscriptions")
      .select("provider, provider_subscription_id, plan, status")
      .eq("user_id", userId).maybeSingle();

    if (!sub || sub.plan === "free" || !sub.provider_subscription_id) {
      return jsonResponse({ error: "no_subscription" }, 404, cors);
    }

    if (sub.provider === "paypal") {
      // PayPal has no per-subscription portal link; users manage recurring
      // payments from their account. Sandbox vs live is inferred from the API url.
      const sandbox = (Deno.env.get("PAYPAL_API_URL") ?? "").includes("sandbox");
      const base = sandbox
        ? "https://www.sandbox.paypal.com"
        : "https://www.paypal.com";
      return jsonResponse({ url: `${base}/myaccount/autopay/` }, 200, cors);
    }

    // Whop: the membership carries the buyer's own billing page (manage,
    // update the card, cancel).
    if (!whopConfigured()) {
      return jsonResponse({ error: "not_available" }, 503, cors);
    }
    let membership;
    try {
      membership = await fetchWhopMembership(sub.provider_subscription_id);
    } catch (_) {
      return jsonResponse({ error: "provider_error" }, 502, cors);
    }
    const url: string | undefined = membership?.manage_url ?? undefined;
    if (!url) return jsonResponse({ error: "not_available" }, 404, cors);
    return jsonResponse({ url }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
