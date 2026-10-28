// SmartBudget — billing-config (Supabase Edge Function, Deno).
//
// Tells the app which payment methods are actually configured, so the Plans
// screen only offers providers whose secrets are set. Returns no secrets — only
// a list of enabled provider names, and whether every one of them is a test
// (sandbox) account — the only case where the app's payment test mode opens.
// While the founding offer runs (FOUNDING_OFFER_ENDS_AT) and its Whop plan is
// in billing_prices, it says so, so the app shows the first-year price.
//
//   POST -> { providers: ["whop", "paypal"], sandbox: false,
//             offer?: { yearlyUsd: 39.99, endsAt: "2027-01-31T23:59:59.000Z" } }
//
// Deploy:  supabase functions deploy billing-config
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { allSandbox, foundingOffer, planToPrice } from "../_shared/billing.ts";
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
    // Shown only when the checkout can actually sell it.
    const running = providers.includes("whop") ? foundingOffer() : null;
    const offer = running &&
        await planToPrice(serviceClient(), "pro", "yearly", "whop", "founding")
      ? running
      : null;
    return jsonResponse({ providers, sandbox, ...(offer ? { offer } : {}) }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});

