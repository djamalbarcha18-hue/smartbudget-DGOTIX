// SmartBudget — billing-config (Supabase Edge Function, Deno).
//
// Tells the app which payment methods are actually configured, so the Plans
// screen only offers providers whose secrets are set. Returns no secrets — only
// a list of enabled provider names, and whether every one of them is a test
// (sandbox) account — the only case where the app's payment test mode opens.
//
//   POST -> { providers: ["paddle", "paypal"], sandbox: false }
//
// Deploy:  supabase functions deploy billing-config
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId } from "../_shared/auth.ts";
import { allSandbox } from "../_shared/billing.ts";
import { paypalApiBase, paypalConfigured } from "../_shared/paypal.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  try {
    await requireUserId(req);
    const providers: string[] = [];
    const paddleReady = ["PADDLE_API_KEY", "PADDLE_CLIENT_TOKEN"]
      .every((k) => (Deno.env.get(k) ?? "").trim());
    if (paddleReady) providers.push("paddle");
    if (paypalConfigured()) providers.push("paypal");
    // Paddle with no API URL set is live.
    const sandbox = allSandbox(providers, {
      paypal: paypalApiBase(),
      paddle: Deno.env.get("PADDLE_API_URL") ?? "",
    });
    return jsonResponse({ providers, sandbox }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});

