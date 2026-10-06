// Usage reserved before a model is called (supabase/security_hardening.sql):
// one database call checks the user's allowance and the platform-wide monthly
// limit and counts the request atomically, so parallel requests can't all slip
// past the check. A request that then fails gives its reservation back.
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.117.2";
import type { Allowance, Trust, UsageKind } from "./quota.ts";

export type { UsageKind };

/**
 * "ok" (counted), "quota" (the user's allowance is spent), "daily" (the
 * user's daily cap), "global" (the platform-wide monthly limit is reached),
 * "pool" (the monthly share for this kind of account is spent), "error" (the
 * database couldn't decide: refuse), or null when the database doesn't have
 * the function yet: the caller then checks and counts as before.
 */
export type Reservation =
  | "ok"
  | "quota"
  | "daily"
  | "global"
  | "pool"
  | "error"
  | null;

/** What one request is checked against. */
export interface UsageLimits {
  allow: Allowance;
  daily: number;
  trust: Trust;
}

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

/**
 * Shares of the platform-wide monthly limit: accounts that don't pay use at
 * most UNPAID_SHARE_PERCENT of it (default 70), new accounts at most
 * NEW_SHARE_PERCENT (default 20), so paying users always keep the rest.
 */
export function poolLimits(
  kind: UsageKind,
): { unpaid: number | null; fresh: number | null } {
  const global = globalMonthlyLimit(kind);
  if (global == null) return { unpaid: null, fresh: null };
  const pct = (name: string, fallback: number) => {
    const raw = (Deno.env.get(name) ?? "").trim();
    const n = Number(raw);
    return raw && Number.isFinite(n) && n >= 0 && n <= 100 ? n : fallback;
  };
  return {
    unpaid: Math.floor(global * pct("UNPAID_SHARE_PERCENT", 70) / 100),
    fresh: Math.floor(global * pct("NEW_SHARE_PERCENT", 20) / 100),
  };
}

function pool(trust: Trust): "paid" | "unpaid" | "new" {
  return trust === "paid" ? "paid" : trust === "new" ? "new" : "unpaid";
}

const RESULTS = new Set(["ok", "quota", "daily", "global", "pool"]);

export async function reserveUsage(
  db: SupabaseClient,
  userId: string,
  kind: UsageKind,
  month: string,
  limits: UsageLimits,
): Promise<Reservation> {
  const base = {
    p_user: userId,
    p_kind: kind,
    p_month: month,
    p_limit: limits.allow.limit,
    p_lifetime: limits.allow.window === "lifetime",
    p_global_limit: globalMonthlyLimit(kind),
  };
  const shares = poolLimits(kind);
  let { data, error } = await db.rpc("reserve_usage", {
    ...base,
    p_daily_limit: limits.daily,
    p_pool: pool(limits.trust),
    p_unpaid_limit: shares.unpaid,
    p_new_limit: shares.fresh,
  });
  if (error?.code === "PGRST202") {
    // supabase/abuse_limits.sql not run yet: the previous checks.
    ({ data, error } = await db.rpc("reserve_usage", base));
    if (error?.code === "PGRST202") return null;
  }
  if (error) return "error";
  return RESULTS.has(data) ? data as Reservation : "error";
}

export async function releaseUsage(
  db: SupabaseClient,
  userId: string,
  kind: UsageKind,
  month: string,
  trust?: Trust,
): Promise<void> {
  try {
    const base = { p_user: userId, p_kind: kind, p_month: month };
    const { error } = await db.rpc("release_usage", {
      ...base,
      p_pool: trust ? pool(trust) : null,
    });
    if (error?.code === "PGRST202") await db.rpc("release_usage", base);
  } catch (_) {
    // Best effort: at worst one request too many is counted.
  }
}

/** Per-account rate limits: [window in seconds, most calls in a window]. */
export const RATE_LIMITS = {
  ai: [60, 10],
  ocr: [60, 6],
  checkout: [3600, 10],
  manage: [3600, 30],
  delete: [3600, 5],
} as const;

/**
 * Counts one call; true when the account is over its rate limit. Not limited
 * while the database lacks rate_limit_hit (supabase/abuse_limits.sql) or
 * can't answer: the allowances above still apply.
 */
export async function rateLimited(
  db: SupabaseClient,
  userId: string,
  bucket: keyof typeof RATE_LIMITS,
): Promise<boolean> {
  const [windowS, max] = RATE_LIMITS[bucket];
  try {
    const { data, error } = await db.rpc("rate_limit_hit", {
      p_user: userId,
      p_bucket: bucket,
      p_window_s: windowS,
      p_max: max,
    });
    return !error && data === false;
  } catch (_) {
    return false;
  }
}
