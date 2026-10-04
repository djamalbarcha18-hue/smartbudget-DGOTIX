// SmartBudget — delete-account (Supabase Edge Function, Deno).
//
// Deletes the signed-in user's account and everything stored for them on the
// server. Every table references auth.users with ON DELETE CASCADE, so removing
// the auth user removes their rows too (profile, transactions, budgets, goals,
// cloud backup, AI usage, coupons, subscription record). The AI request log
// keeps no link to the account, so its rows are deleted here.
//
// Required by Google Play and the App Store for apps that let users create an
// account. A paid subscription that is still running must be cancelled first,
// so nobody keeps being billed for an account that no longer exists.
//
//   POST -> { deleted: true } | { error: "active_subscription" | ... }
//
// Deploy:  supabase functions deploy delete-account
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
      .select("plan, status")
      .eq("user_id", userId).maybeSingle();
    const paid = sub && sub.plan !== "free" &&
      ["active", "trialing", "past_due"].includes(String(sub.status ?? ""));
    if (paid) return jsonResponse({ error: "active_subscription" }, 409, cors);

    const { error } = await db.auth.admin.deleteUser(userId);
    if (error) return jsonResponse({ error: "delete_failed" }, 500, cors);
    // Numbers only (no questions or answers), but they were this user's.
    await db.from("ai_request_log").delete().eq("user_id", userId);
    return jsonResponse({ deleted: true }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
