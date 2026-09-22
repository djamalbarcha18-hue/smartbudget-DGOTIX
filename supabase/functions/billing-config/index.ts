// SmartBudget — billing-config (Supabase Edge Function, Deno).
//
// Tells the app which payment methods are actually configured, so the Plans
// screen only offers providers whose secrets are set. Returns no secrets — only
// a list of enabled provider names.
//
//   POST -> { providers: ["paddle", "paypal"] }
//
// Deploy:  supabase functions deploy billing-config
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId } from "../_shared/auth.ts";
import { paypalConfigured } from "../_shared/paypal.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  try {
    await requireUserId(req);
    const providers: string[] = [];
    if ((Deno.env.get("PADDLE_API_KEY") ?? "").trim()) providers.push("paddle");
    if (paypalConfigured()) providers.push("paypal");
    return jsonResponse({ providers }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
