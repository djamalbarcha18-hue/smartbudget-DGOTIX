// SmartBudget — plan quotas (server-side source of truth for enforcement).
//
// MIRRORS lib/features/billing/domain/feature_catalog.dart and docs/PRICING.md.
// KEEP IN SYNC: when a quota changes there, change it here (and vice-versa).
// The server is the real enforcer; the client numbers are the UX mirror.

export type Plan = "free" | "basic" | "pro";
export type QuotaWindow = "lifetime" | "monthly";

export interface Allowance {
  readonly limit: number;
  readonly window: QuotaWindow;
}

/** DGOTIX AI answers per period (docs/PRICING.md §2). */
export const AI_QUOTA: Record<Plan, Allowance> = {
  free: { limit: 5, window: "lifetime" },
  basic: { limit: 30, window: "monthly" },
  pro: { limit: 150, window: "monthly" },
};

/** Cloud receipt OCR scans per period (docs/PRICING.md §3). */
export const OCR_QUOTA: Record<Plan, Allowance> = {
  free: { limit: 3, window: "lifetime" },
  basic: { limit: 15, window: "monthly" },
  pro: { limit: 100, window: "monthly" },
};

/**
 * Secondary monthly cost guard (docs/PRICING.md §4). A per-request cap alone
 * cannot stop a run of unusually expensive answers, so a plan-scoped monthly
 * USD ceiling backs the request count. These are internal guardrails, not
 * user-facing prices — set generously so a normal month never hits them.
 */
export const AI_MONTHLY_COST_CEILING_USD: Record<Plan, number> = {
  free: 0.25,
  basic: 2.0,
  pro: 10.0,
};

const RANK: Record<Plan, number> = { free: 0, basic: 1, pro: 2 };

/** Coerce an unknown/invalid stored plan to the safe FREE default. */
export function normalizePlan(p: unknown): Plan {
  return p === "basic" || p === "pro" ? p : "free";
}

/**
 * The plan actually in force now: the higher of the paid plan and an active
 * trial. An expired or malformed trial is ignored (falls back to the plan).
 */
export function effectivePlan(
  plan: Plan,
  trialPlan: Plan | null,
  trialExpiresAt: string | null,
  now: Date = new Date(),
): Plan {
  if (trialPlan && trialExpiresAt) {
    const exp = new Date(trialExpiresAt);
    if (!isNaN(exp.getTime()) && now < exp && RANK[trialPlan] >= RANK[plan]) {
      return trialPlan;
    }
  }
  return plan;
}
