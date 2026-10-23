// SmartBudget — billing-config (Supabase Edge Function, Deno).
//
// Tells the app which payment methods are actually configured, so the Plans
// screen only offers providers whose secrets are set. Returns no secrets — only
// a list of enabled provider names, and whether every one of them is a test
// (sandbox) account — the only case where the app's payment test mode opens.
//
//   POST -> { providers: ["whop", "paypal"], sandbox: false }
//
// Deploy:  supabase functions deploy billing-config
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId } from "../_shared/auth.ts";
import { allSandbox } from "../_shared/billing.ts";
import { paypalApiBase, paypalConfigured } from "../_shared/paypal.ts";
import { whopApiBase, whopConfigured } from "../_shared/whop.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  try {
    await requireUserId(req);
    const providers: string[] = [];
    if (whopConfigured()) providers.push("whop");
    if (paypalConfigured()) providers.push("paypal");
    // Whop with no API URL set is live.
    const sandbox = allSandbox(providers, {
      paypal: paypalApiBase(),
      whop: whopApiBase(),
    });
    return jsonResponse({ providers, sandbox }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});

