// Usage reserved before a model is called (supabase/security_hardening.sql):
// one database call checks the user's allowance and the platform-wide monthly
// limit and counts the request atomically, so parallel requests can't all slip
// past the check. A request that then fails gives its reservation back.
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.117.2";
import type { Allowance } from "./quota.ts";

export type UsageKind = "ai" | "ocr";

/**
 * "ok" (counted), "quota" (the user's allowance is spent), "global" (the
 * platform-wide monthly limit is reached), or null when the database doesn't
 * have the function yet: the caller then checks and counts as before.
 */
export type Reservation = "ok" | "quota" | "global" | null;

/** Platform-wide monthly limits, from Edge Function secrets. */
export function globalMonthlyLimit(kind: UsageKind): number | null {
  const name = kind === "ai"
    ? "AI_GLOBAL_MONTHLY_REQUESTS"
    : "OCR_GLOBAL_MONTHLY_SCANS";
  const fallback = kind === "ai" ? 5000 : 3000;
  const raw = (Deno.env.get(name) ?? "").trim();
  if (raw === "off") return null;
  const n = Number(raw);
  return raw && Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
}

export async function reserveUsage(
  db: SupabaseClient,
  userId: string,
  kind: UsageKind,
  month: string,
  allow: Allowance,
): Promise<Reservation> {
  const { data, error } = await db.rpc("reserve_usage", {
    p_user: userId,
    p_kind: kind,
    p_month: month,
    p_limit: allow.limit,
    p_lifetime: allow.window === "lifetime",
    p_global_limit: globalMonthlyLimit(kind),
  });
  if (error) return null;
  return data === "ok" || data === "quota" || data === "global" ? data : null;
}

export async function releaseUsage(
  db: SupabaseClient,
  userId: string,
  kind: UsageKind,
  month: string,
): Promise<void> {
  try {
    await db.rpc("release_usage", {
      p_user: userId,
      p_kind: kind,
      p_month: month,
    });
  } catch (_) {
    // Best effort: at worst one request too many is counted.
  }
}
