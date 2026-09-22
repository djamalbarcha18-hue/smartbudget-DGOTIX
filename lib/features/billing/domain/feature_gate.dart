/// FeatureGate — the ONE decision function for "can this user do X right now".
///
/// Pure and synchronous: given the user's [Plan] and current usage, it returns a
/// [GateDecision]. No `if (plan == pro)` lives anywhere else — widgets, the AI
/// card and the OCR flow all read a decision from here. The server is the real
/// enforcer (see the ai-gateway Edge Function); this gate is the client-side UX
/// mirror that keeps the app honest and drives nudges/CTAs.
library;

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// Why a feature is (dis)allowed. Presentation maps these to localized copy.
enum GateReason {
  /// Allowed — go ahead.
  ok,

  /// The plan is below the feature's minimum tier (a pure boolean gate).
  needsUpgrade,

  /// The plan qualifies but the metered allowance for the period is spent.
  quotaReached,
}

/// The result of evaluating one feature. Immutable and cheap to build.
class GateDecision {
  const GateDecision({
    required this.feature,
    required this.allowed,
    required this.reason,
    this.remaining,
    this.limit,
    this.window,
    this.suggestedTier,
  });

  final Feature feature;
  final bool allowed;
  final GateReason reason;

  /// Remaining metered budget for the period. Null for boolean gates and for
  /// unlimited allowances.
  final int? remaining;

  /// The metered limit for the period, or null (boolean/unlimited).
  final int? limit;

  /// The reset window for a metered feature, or null.
  final QuotaWindow? window;

  /// The plan the Upgrade CTA should point at, or null when nothing higher
  /// would help (already at the top, or not gated).
  final Plan? suggestedTier;

  bool get isMetered => limit != null;

  /// Fraction of the period's allowance consumed, 0..1. Null when not metered
  /// or unlimited. Drives the 80/90/100 nudges.
  double? get usedFraction {
    final int? l = limit;
    final int? r = remaining;
    if (l == null || r == null || l <= 0) return null;
    final int used = l - r;
    final double f = used / l;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }
}

/// The gate. Stateless; call [evaluate] with the plan and current usage.
abstract final class FeatureGate {
  /// Decide whether [feature] is available for [plan]. [used] is the count
  /// already consumed this period for a metered feature (ignored for boolean
  /// gates). Usage is clamped to be non-negative.
  static GateDecision evaluate(
    Feature feature, {
    required Plan plan,
    int used = 0,
  }) {
    final int consumed = used < 0 ? 0 : used;
    final Plan minTier = FeatureCatalog.minTierFor(feature);

    // Boolean gate below its minimum tier: needs an upgrade to that tier.
    if (!plan.atLeast(minTier)) {
      return GateDecision(
        feature: feature,
        allowed: false,
        reason: GateReason.needsUpgrade,
        suggestedTier: minTier,
      );
    }

    final Quota? quota = FeatureCatalog.quotaFor(feature, plan);

    // Boolean gate the plan satisfies: allowed, nothing metered.
    if (quota == null) {
      return GateDecision(
        feature: feature,
        allowed: true,
        reason: GateReason.ok,
      );
    }

    // Unlimited metered allowance: always allowed, no counter shown.
    if (quota.isUnlimited) {
      return GateDecision(
        feature: feature,
        allowed: true,
        reason: GateReason.ok,
        window: quota.window,
      );
    }

    final int remaining =
        (quota.limit - consumed) < 0 ? 0 : (quota.limit - consumed);
    final bool allowed = remaining > 0;

    return GateDecision(
      feature: feature,
      allowed: allowed,
      reason: allowed ? GateReason.ok : GateReason.quotaReached,
      remaining: remaining,
      limit: quota.limit,
      window: quota.window,
      suggestedTier:
          allowed ? null : FeatureCatalog.nextTierWithMore(feature, plan),
    );
  }
}
