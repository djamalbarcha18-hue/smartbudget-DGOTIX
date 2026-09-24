/// Feature catalog — the single source of truth for "what does each plan get".
///
/// Every gate in the app resolves through here; there is no `if (plan == pro)`
/// scattered in widgets. A feature is either a **boolean gate** (needs at least
/// [FeatureRule.minTier]) or **metered** (also carries a per-plan [Quota]).
///
/// Mirrors docs/PRICING.md. When they disagree, THIS FILE wins — fix the doc.
library;

import 'package:smartbudget/features/billing/domain/plan.dart';

/// The capabilities the app gates on. Add here, never invent gate keys inline.
enum Feature {
  /// DGOTIX AI assistant (server gateway). Metered.
  dgotixAi,

  /// Cloud receipt OCR (server). Metered. On-device OCR is NOT gated and has no
  /// entry here — it is always free and unlimited.
  cloudOcr,

  /// Advanced reports & analytics (deep breakdowns, longer history).
  advancedReports,

  /// Full cloud sync & backup (FREE gets basic backup, paid gets full sync).
  cloudSyncFull,

  /// Full portfolio & markets (FREE can view; paid unlocks the rest).
  portfolioFull,

  /// Priority support.
  prioritySupport,

  /// Smart salary split: suggests a per-category budget from the user's own
  /// recent spending (see features/salary_split).
  salarySplit,

  /// Smart alerts: budget forecasts, unusual spending and weekly/monthly
  /// summaries in the notifications bell. Reserved for YEARLY subscribers.
  smartAlerts,

  /// Using a personal AI key (BYOK) for DGOTIX AI. PRO only: on other plans
  /// the assistant runs through the server gateway and its plan quota.
  byok,
}

/// How a metered quota resets.
enum QuotaWindow {
  /// One-time allowance that never refills (FREE intro allowances).
  lifetime,

  /// Refills at the start of each calendar month.
  monthly,
}

/// A metered allowance for one (feature, plan). [limit] < 0 means unlimited.
class Quota {
  const Quota(this.limit, this.window);
  const Quota.unlimited() : this(-1, QuotaWindow.monthly);

  final int limit;
  final QuotaWindow window;

  bool get isUnlimited => limit < 0;
}

/// The gate for one feature: the minimum plan, and (if metered) the per-plan
/// quota. A feature with no [quotas] is a pure boolean gate.
class FeatureRule {
  const FeatureRule({
    required this.feature,
    required this.minTier,
    this.quotas,
    this.yearlyOnly = false,
  });

  final Feature feature;
  final Plan minTier;

  /// Only for paid plans billed yearly (any tier at or above [minTier]).
  final bool yearlyOnly;

  /// Per-plan allowance for metered features; null ⇒ boolean gate only.
  final Map<Plan, Quota>? quotas;

  bool get isMetered => quotas != null;
}

/// The catalog. Read via [ruleFor] / [quotaFor]; do not duplicate these numbers.
abstract final class FeatureCatalog {
  /// Locked quotas per docs/PRICING.md §2–§3.
  static const Map<Feature, FeatureRule> _rules = <Feature, FeatureRule>{
    Feature.dgotixAi: FeatureRule(
      feature: Feature.dgotixAi,
      minTier: Plan.free,
      quotas: <Plan, Quota>{
        Plan.free: Quota(5, QuotaWindow.lifetime),
        Plan.basic: Quota(30, QuotaWindow.monthly),
        Plan.pro: Quota(150, QuotaWindow.monthly),
      },
    ),
    Feature.cloudOcr: FeatureRule(
      feature: Feature.cloudOcr,
      minTier: Plan.free,
      quotas: <Plan, Quota>{
        Plan.free: Quota(3, QuotaWindow.lifetime),
        Plan.basic: Quota(15, QuotaWindow.monthly),
        Plan.pro: Quota(100, QuotaWindow.monthly),
      },
    ),
    Feature.advancedReports: FeatureRule(
      feature: Feature.advancedReports,
      minTier: Plan.basic,
    ),
    Feature.cloudSyncFull: FeatureRule(
      feature: Feature.cloudSyncFull,
      minTier: Plan.basic,
    ),
    Feature.portfolioFull: FeatureRule(
      feature: Feature.portfolioFull,
      minTier: Plan.basic,
    ),
    Feature.prioritySupport: FeatureRule(
      feature: Feature.prioritySupport,
      minTier: Plan.pro,
    ),
    Feature.salarySplit: FeatureRule(
      feature: Feature.salarySplit,
      minTier: Plan.basic,
    ),
    Feature.smartAlerts: FeatureRule(
      feature: Feature.smartAlerts,
      minTier: Plan.basic,
      yearlyOnly: true,
    ),
    Feature.byok: FeatureRule(
      feature: Feature.byok,
      minTier: Plan.pro,
    ),
  };

  static FeatureRule ruleFor(Feature f) => _rules[f]!;

  /// The metered allowance for [f] on [plan], or null when [f] is a boolean
  /// gate. Falls back to the plan's own quota; a plan below [minTier] returns a
  /// zero allowance so callers uniformly see "no budget".
  static Quota? quotaFor(Feature f, Plan plan) {
    final FeatureRule r = ruleFor(f);
    if (r.quotas == null) return null;
    if (!plan.atLeast(r.minTier)) return const Quota(0, QuotaWindow.monthly);
    return r.quotas![plan] ?? const Quota(0, QuotaWindow.monthly);
  }

  /// The lowest plan that unlocks [f] at all (its [minTier]).
  static Plan minTierFor(Feature f) => ruleFor(f).minTier;

  /// The lowest plan that would give a *larger* metered allowance than [plan]
  /// for a metered feature, or null when already at the top (or not metered).
  /// Used to point the upgrade CTA at the right next tier.
  static Plan? nextTierWithMore(Feature f, Plan plan) {
    final FeatureRule r = ruleFor(f);
    if (r.quotas == null) {
      return plan.atLeast(r.minTier) ? null : r.minTier;
    }
    final int current = (quotaFor(f, plan)?.limit ?? 0);
    for (final Plan p in Plan.values) {
      if (!p.atLeast(plan) || p == plan) continue;
      final int next = quotaFor(f, p)?.limit ?? 0;
      // Unlimited (-1) or a strictly higher finite cap both count as "more".
      if (next < 0 || (current >= 0 && next > current)) return p;
    }
    return null;
  }
}
