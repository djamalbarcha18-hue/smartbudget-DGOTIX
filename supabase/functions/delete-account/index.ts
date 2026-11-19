// SmartBudget — delete-account (Supabase Edge Function, Deno).
//
// Deletes the signed-in user's account and everything stored for them on the
// server. Every table references auth.users with ON DELETE CASCADE, so removing
// the auth user removes their rows too (profile, transactions, budgets, goals,
// cloud backup, AI usage, coupons, subscription record). The AI request log
// keeps no link to the account, so its rows are deleted here.
//
// Required by Google Play and the App Store for apps that let users create an
// account. A paid subscription that will bill again must be cancelled first,
// so nobody keeps being billed for an account that no longer exists (one
// already cancelled, running to the end of its period, doesn't block).
//
// The caller must have signed in recently (REAUTH_WINDOW_MS): a phone left
// unlocked, or a session token copied from a device, can't erase an account.
//
//   POST -> { deleted: true }
//         | { error: "reauth_required" | "active_subscription" | ... }
//
// Deploy:  supabase functions deploy delete-account
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { rateLimited } from "../_shared/usage.ts";

/** How recently the caller must have signed in to delete the account. */
export const REAUTH_WINDOW_MS = 15 * 60 * 1000;

/**
 * When the caller last signed in, from the verified session JWT's `amr`
 * claim (Supabase records each sign-in method with its time there; a token
 * refresh does not change it). Null when the token carries no such claim.
 */
export function lastSignInMs(req: Request): number | null {
  const token = (req.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "").trim();
  const part = token.split(".")[1];
  if (!part) return null;
  try {
    const b64 = part.replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(b64 + "=".repeat((4 - b64.length % 4) % 4)));
    const times = (Array.isArray(payload?.amr) ? payload.amr : [])
      .map((a: { timestamp?: unknown }) => Number(a?.timestamp))
      .filter((t: number) => Number.isFinite(t) && t > 0);
    return times.length ? Math.max(...times) * 1000 : null;
  } catch {
    return null;
  }
}

/** Still billing: active, trialing or past due, and not set to end. */
interface SubRow {
  plan?: string;
  status?: string | null;
  cancel_at_period_end?: boolean | null;
}

function bills(row: SubRow | null | undefined): boolean {
  return row != null && row.plan !== "free" &&
    ["active", "trialing", "past_due"].includes(String(row.status ?? "")) &&
    row.cancel_at_period_end !== true;
}

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    // The token was just verified above, so its claims can be read. A token
    // without the claim (not expected from Supabase) is let through rather
    // than locking every deletion out.
    const signedIn = lastSignInMs(req);
    if (signedIn != null && Date.now() - signedIn > REAUTH_WINDOW_MS) {
      return jsonResponse({ error: "reauth_required" }, 401, cors);
    }
    const db = serviceClient();
    if (await rateLimited(db, userId, "delete")) {
      return jsonResponse({ error: "rate_limited" }, 429, cors);
    }

    // Every provider subscription, plus the account's summary row.
    const { data: sub } = await db.from("subscriptions")
      .select("plan, status, cancel_at_period_end")
      .eq("user_id", userId).maybeSingle();
    const { data: subs } = await db.from("billing_subscriptions")
      .select("plan, status, cancel_at_period_end")
      .eq("user_id", userId);
    const paid = bills(sub) || (subs ?? []).some(bills);
    if (paid) return jsonResponse({ error: "active_subscription" }, 409, cors);

    // Kept under a hash of the e-mail, so signing up again doesn't bring
    // back the trial or the free lifetime allowances (account_tombstones.sql).
    // supabase-js reports a failed call in `error` rather than throwing, so
    // both are checked. If it can't be recorded the account is NOT deleted
    // (the user can try again): deleting anyway would let anyone reset the
    // trial and the free lifetime allowances by deleting and signing up again.
    let tombstoned = false;
    try {
      const { error: tErr } = await db.rpc("record_account_tombstone", { p_user: userId });
      tombstoned = !tErr;
    } catch (_) { /* tombstoned stays false */ }
    if (!tombstoned) return jsonResponse({ error: "try_again" }, 503, cors);
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
