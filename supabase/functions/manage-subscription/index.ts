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

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const db = serviceClient();
    const { data: sub } = await db.from("subscriptions")
      .select("provider, provider_subscription_id, plan")
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

    // Paddle: the subscription carries hosted management URLs (update / cancel).
    const apiKey = (Deno.env.get("PADDLE_API_KEY") ?? "").trim();
    const apiUrl = (Deno.env.get("PADDLE_API_URL") ?? "https://api.paddle.com")
      .replace(/\/+$/, "");
    if (!apiKey) return jsonResponse({ error: "not_available" }, 503, cors);

    const res = await fetch(
      `${apiUrl}/subscriptions/${sub.provider_subscription_id}`,
      { headers: { "Authorization": `Bearer ${apiKey}` } },
    );
    if (!res.ok) return jsonResponse({ error: "provider_error" }, 502, cors);
    const data = await res.json().catch(() => ({}));
    const urls = data?.data?.management_urls ?? {};
    const url: string | undefined = urls.cancel ?? urls.update_payment_method;
    if (!url) return jsonResponse({ error: "not_available" }, 404, cors);
    return jsonResponse({ url }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
