// SmartBudget — plan quotas (server-side source of truth for enforcement).
//
// MIRRORS lib/features/billing/domain/feature_catalog.dart and docs/PRICING.md.
// KEEP IN SYNC: when a quota changes there, change it here (and vice-versa).
// The server is the real enforcer; the client numbers are the UX mirror.

export type Plan = "free" | "pro";
export type QuotaWindow = "lifetime" | "monthly";

export interface Allowance {
  readonly limit: number;
  readonly window: QuotaWindow;
  /**
   * What the account had already used when this allowance began (a trial's
   * own allowance is counted from the trial's start). [limit] includes it:
   * the allowance itself is `limit - offset`.
   */
  readonly offset?: number;
}

/** DGOTIX AI answers per period (docs/PRICING.md §2). */
export const AI_QUOTA: Record<Plan, Allowance> = {
  free: { limit: 2, window: "lifetime" },
  // 80 a month (owner's AI policy, docs/AI_ARCHITECTURE.md): unused requests
  // are not carried over.
  pro: { limit: 80, window: "monthly" },
};

/** Cloud receipt OCR scans per period (docs/PRICING.md §3). */
export const OCR_QUOTA: Record<Plan, Allowance> = {
  free: { limit: 2, window: "monthly" },
  pro: { limit: 50, window: "monthly" },
};

/**
 * Secondary monthly cost guard (docs/PRICING.md §4). A per-request cap alone
 * cannot stop a run of unusually expensive answers, so a plan-scoped monthly
 * USD ceiling backs the request count. These are internal guardrails, not
 * user-facing prices — set generously so a normal month never hits them.
 */
export const AI_MONTHLY_COST_CEILING_USD: Record<Plan, number> = {
  free: 0.25,
  // 80 requests of at most 5,000 tokens cost about $0.30 even on the pricier
  // model; this is the safety net above that.
  pro: 0.75,
};

/**
 * The costly part of a PRO trial is a small, fixed allowance (owner's decision,
 * 2026-11-08): the rest of PRO is open for the trial, but the assistant and
 * cloud scans cost money per call, so a trial gets a small allowance of each.
 * docs/PRICING.md §7.
 *
 * The allowance belongs to the trial (owner's decision, 2026-11-12): 5 and 5
 * for its 14 days, counted from the moment it starts, whatever was used before
 * and whichever months it spans. start_pro_trial() records the account's
 * usage so far (supabase/launch_offers.sql) and [trialAllowance] counts from
 * there. A trial started before that was recorded falls back to counting in
 * the calendar month.
 */
export const TRIAL_AI_QUOTA: Allowance = { limit: 5, window: "monthly" };
export const TRIAL_OCR_QUOTA: Allowance = { limit: 5, window: "monthly" };
export const TRIAL_AI_COST_CEILING_USD = 0.3;

/**
 * Display prices in USD (mirrors lib/features/billing/domain/plan.dart and
 * docs/PRICING.md). Used by coupon math to compute a discounted price. The
 * billing provider remains authoritative at real checkout. `yearly` is null
 * where a plan has no such option. KEEP IN SYNC with the Dart Plan prices.
 */
export const PLAN_PRICE_USD: Record<
  Plan,
  { monthly: number; yearly: number | null }
> = {
  free: { monthly: 0, yearly: null },
  pro: { monthly: 9.99, yearly: 59.99 },
};

const RANK: Record<Plan, number> = { free: 0, pro: 1 };

/**
 * Coerce an unknown/invalid stored plan to the safe FREE default. A value
 * left from the retired plan ("basic", merged into PRO) reads as PRO, so a
 * database not yet migrated (supabase/subscription_lifecycle.sql) costs
 * nobody their plan.
 */
export function normalizePlan(p: unknown): Plan {
  return p === "pro" || p === "basic" ? "pro" : "free";
}

/**
 * The plan actually in force now: the higher of the paid plan and an active
 * trial. An expired or malformed trial is ignored (falls back to the plan).
 */
/**
 * Beta: every signed-in user gets PRO limits (mirrors AppEnv.betaAllAccess in
 * the app). ON by default while SmartBudget is in beta; set the Edge Function
 * secret BETA_ALL_ACCESS=false when paid plans go live.
 */
export function betaAllAccess(): boolean {
  try {
    return (Deno.env.get("BETA_ALL_ACCESS") ?? "true").trim().toLowerCase() !==
      "false";
  } catch {
    return true;
  }
}

export function effectivePlan(
  plan: Plan,
  trialPlan: Plan | null,
  trialExpiresAt: string | null,
  now: Date = new Date(),
): Plan {
  if (betaAllAccess()) return "pro";
  if (trialPlan && trialExpiresAt) {
    const exp = new Date(trialExpiresAt);
    if (!isNaN(exp.getTime()) && now < exp && RANK[trialPlan] >= RANK[plan]) {
      return trialPlan;
    }
  }
  return plan;
}

/**
 * Whether a trial (not a purchase, and not the beta) is what puts the account
 * above the plan it pays for. [beta] is a parameter so tests can set it.
 */
export function onTrial(
  plan: Plan,
  paidPlan: Plan,
  beta: boolean = betaAllAccess(),
): boolean {
  return !beta && RANK[plan] > RANK[paidPlan];
}

/**
 * A trial's allowance counted from the trial's start: [base] is the account's
 * all-time usage when the trial began (null when it wasn't recorded: the
 * allowance is then counted in the calendar month, as before).
 */
export function trialAllowance(quota: Allowance, base: number | null): Allowance {
  if (base === null || !Number.isInteger(base) || base < 0) return quota;
  return { limit: base + quota.limit, window: "lifetime", offset: base };
}

/**
 * AI answers allowed: the plan's, or the small trial allowance on a trial
 * ([trialBase]: see [trialAllowance]).
 */
export function aiAllowance(
  plan: Plan,
  paidPlan: Plan,
  beta: boolean = betaAllAccess(),
  trialBase: number | null = null,
): Allowance {
  return onTrial(plan, paidPlan, beta)
    ? trialAllowance(TRIAL_AI_QUOTA, trialBase)
    : AI_QUOTA[plan];
}

/**
 * Cloud scans allowed: the plan's, or the small trial allowance on a trial
 * ([trialBase]: see [trialAllowance]).
 */
export function ocrAllowance(
  plan: Plan,
  paidPlan: Plan,
  beta: boolean = betaAllAccess(),
  trialBase: number | null = null,
): Allowance {
  return onTrial(plan, paidPlan, beta)
    ? trialAllowance(TRIAL_OCR_QUOTA, trialBase)
    : OCR_QUOTA[plan];
}

/** The monthly AI cost guard: the plan's, or a smaller one on a trial. */
export function aiCostCeiling(
  plan: Plan,
  paidPlan: Plan,
  beta: boolean = betaAllAccess(),
): number {
  return onTrial(plan, paidPlan, beta)
    ? TRIAL_AI_COST_CEILING_USD
    : AI_MONTHLY_COST_CEILING_USD[plan];
}

// ---- Limits against mass sign-ups (supabase/abuse_limits.sql) ----
// Signing up is free, so the limits below depend on what an account has shown
// rather than on IP addresses: paying is the strongest signal; a confirmed
// account older than NEW_ACCOUNT_DAYS comes next. Beta's PRO limits apply in
// full only to established and paying accounts.

export type UsageKind = "ai" | "ocr";

/** paid: a plan bought through checkout; new: young or unconfirmed account. */
export type Trust = "paid" | "established" | "new";

/** Accounts younger than this many days count as new (secret NEW_ACCOUNT_DAYS). */
export function newAccountDays(): number {
  try {
    const raw = (Deno.env.get("NEW_ACCOUNT_DAYS") ?? "").trim();
    const n = Number(raw);
    return raw && Number.isFinite(n) && n >= 0 ? n : 7;
  } catch {
    return 7;
  }
}

export function trustOf(
  paidPlan: Plan,
  account: { createdAt: string | null; emailConfirmed: boolean },
  now: Date = new Date(),
): Trust {
  if (paidPlan !== "free") return "paid";
  const created = account.createdAt ? Date.parse(account.createdAt) : NaN;
  const ageDays = (now.getTime() - created) / 86_400_000;
  if (!account.emailConfirmed || !(ageDays >= newAccountDays())) return "new";
  return "established";
}

/** The most a new account may use in its plan's period, whatever the plan. */
export const NEW_ACCOUNT_QUOTA: Record<UsageKind, number> = { ai: 10, ocr: 5 };

/** Per-account daily caps, on top of the monthly or lifetime allowance. */
export const DAILY_LIMIT: Record<Trust, Record<UsageKind, number>> = {
  paid: { ai: 60, ocr: 40 },
  established: { ai: 30, ocr: 15 },
  new: { ai: 5, ocr: 3 },
};

/** The plan's allowance, reduced for a new account. */
export function allowanceFor(
  base: Allowance,
  kind: UsageKind,
  trust: Trust,
): Allowance {
  if (trust !== "new") return base;
  const off = base.offset ?? 0;
  const limit = off + Math.min(base.limit - off, NEW_ACCOUNT_QUOTA[kind]);
  return base.offset === undefined
    ? { limit, window: base.window }
    : { limit, window: base.window, offset: off };
}

/** What the app shows the user about their allowance (computed on the server). */
export interface QuotaInfo {
  readonly limit: number;
  readonly used: number;
  readonly remaining: number;
  readonly window: QuotaWindow;
  /** When a monthly allowance starts over (UTC); null for a one-time one. */
  readonly resetsAt: string | null;
}

export function quotaInfo(
  allow: Allowance,
  used: number,
  now: Date = new Date(),
): QuotaInfo {
  // An allowance that began later (a trial) is shown on its own: 5, not the
  // account's all-time count.
  const off = allow.offset ?? 0;
  const limit = allow.limit - off;
  const u = Math.max(0, Math.min(used - off, limit));
  return {
    limit,
    used: u,
    remaining: limit - u,
    window: allow.window,
    resetsAt: allow.window === "monthly"
      ? new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString()
      : null,
  };
}
