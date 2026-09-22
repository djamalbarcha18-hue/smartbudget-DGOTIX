// SmartBudget — coupon-validate (Supabase Edge Function, Deno).
//
// Validates a marketing coupon code for a given plan/period and returns the
// resulting price (or trial), WITHOUT redeeming it — redemption happens at
// checkout. Coupons are server-only (not client-readable), so codes can't be
// enumerated: this function is the only way to test one.
//
//   POST { code, plan?: "basic"|"pro", period?: "monthly"|"yearly" } ->
//     { valid:true, kind, value, targetPlan, targetPeriod,
//       basePriceUsd?, discountedPriceUsd?, trialDays? }
//   | { valid:false, reason: "invalid"|"expired"|"not_applicable"
//                            |"exhausted"|"already_used" }
//
// With no (or a non-paid) `plan`, it runs in PROBE mode: it still checks the
// window and caps and returns the coupon's kind/value/target, but skips the
// plan/period applicability filter and price math (for a pre-checkout preview).
//
// Deploy:  supabase functions deploy coupon-validate
//          supabase db execute -f supabase/coupons.sql
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import { normalizePlan, type Plan, PLAN_PRICE_USD } from "../_shared/quota.ts";

type Period = "monthly" | "yearly";

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await req.json().catch(() => ({}));
    const code = String(body?.code ?? "").trim().toUpperCase();
    // Probe mode when no paid plan is supplied (pre-checkout preview).
    const probe = body?.plan !== "basic" && body?.plan !== "pro";
    const plan: Plan = normalizePlan(body?.plan);
    const period: Period = body?.period === "yearly" ? "yearly" : "monthly";
    if (!code) return jsonResponse({ valid: false, reason: "invalid" }, 200, cors);

    const db = serviceClient();
    const { data: c } = await db.from("coupons")
      .select(
        "code, kind, value, target_plan, target_period, valid_from, valid_until, max_redemptions, per_user_limit, active",
      )
      .eq("code", code).maybeSingle();

    if (!c || c.active !== true) {
      return jsonResponse({ valid: false, reason: "invalid" }, 200, cors);
    }

    const now = Date.now();
    if (c.valid_from && now < new Date(c.valid_from).getTime()) {
      return jsonResponse({ valid: false, reason: "expired" }, 200, cors);
    }
    if (c.valid_until && now > new Date(c.valid_until).getTime()) {
      return jsonResponse({ valid: false, reason: "expired" }, 200, cors);
    }
    // In probe mode we report the target instead of filtering by it.
    if (!probe && c.target_plan && c.target_plan !== plan) {
      return jsonResponse({ valid: false, reason: "not_applicable" }, 200, cors);
    }
    if (!probe && c.target_period && c.target_period !== period) {
      return jsonResponse({ valid: false, reason: "not_applicable" }, 200, cors);
    }

    // Global cap.
    if (c.max_redemptions != null) {
      const { count } = await db.from("coupon_redemptions")
        .select("id", { count: "exact", head: true }).eq("code", code);
      if ((count ?? 0) >= c.max_redemptions) {
        return jsonResponse({ valid: false, reason: "exhausted" }, 200, cors);
      }
    }
    // Per-user cap.
    const perUser = Number(c.per_user_limit ?? 1);
    const { count: mine } = await db.from("coupon_redemptions")
      .select("id", { count: "exact", head: true })
      .eq("code", code).eq("user_id", userId);
    if ((mine ?? 0) >= perUser) {
      return jsonResponse({ valid: false, reason: "already_used" }, 200, cors);
    }

    const kind = String(c.kind);
    const value = Number(c.value);
    const targets = {
      targetPlan: (c.target_plan as string | null) ?? null,
      targetPeriod: (c.target_period as string | null) ?? null,
    };

    if (kind === "trial_extension") {
      return jsonResponse({
        valid: true,
        kind,
        value,
        ...targets,
        trialDays: Math.max(0, Math.round(value)),
      }, 200, cors);
    }
    if (kind !== "percent" && kind !== "fixed") {
      return jsonResponse({ valid: false, reason: "invalid" }, 200, cors);
    }

    // Probe mode: report the coupon without per-plan price math.
    if (probe) {
      return jsonResponse({ valid: true, kind, value, ...targets }, 200, cors);
    }

    const base = period === "yearly"
      ? PLAN_PRICE_USD[plan].yearly
      : PLAN_PRICE_USD[plan].monthly;
    if (base == null) {
      return jsonResponse({ valid: false, reason: "not_applicable" }, 200, cors);
    }
    const discounted = round2(Math.max(
      0,
      kind === "percent" ? base * (1 - value / 100) : base - value,
    ));

    return jsonResponse({
      valid: true,
      kind,
      value,
      ...targets,
      basePriceUsd: round2(base),
      discountedPriceUsd: discounted,
    }, 200, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});
