/// A marketing coupon's validation outcome (from the `coupon-validate` server
/// function). A coupon changes the PRICE of a checkout (or grants a trial); it
/// never unlocks a feature itself. Validation is server-side only.
library;

enum CouponKind { percent, fixed, trialExtension, unknown }

/// Why a code was rejected (mirrors the function's `reason` strings).
enum CouponReason {
  invalid,
  expired,
  notApplicable,
  exhausted,
  alreadyUsed,
  network,
}

class CouponResult {
  const CouponResult._({
    required this.valid,
    this.kind = CouponKind.unknown,
    this.value = 0,
    this.targetPlan,
    this.targetPeriod,
    this.trialDays,
    this.reason,
  });

  final bool valid;
  final CouponKind kind;
  final double value;
  final String? targetPlan; // 'basic' | 'pro' | null (any)
  final String? targetPeriod; // 'monthly' | 'yearly' | null (any)
  final int? trialDays;
  final CouponReason? reason; // set when !valid

  factory CouponResult.ok({
    required CouponKind kind,
    required double value,
    String? targetPlan,
    String? targetPeriod,
    int? trialDays,
  }) =>
      CouponResult._(
        valid: true,
        kind: kind,
        value: value,
        targetPlan: targetPlan,
        targetPeriod: targetPeriod,
        trialDays: trialDays,
      );

  factory CouponResult.rejected(CouponReason reason) =>
      CouponResult._(valid: false, reason: reason);

  static CouponKind kindFromId(Object? id) => switch (id) {
        'percent' => CouponKind.percent,
        'fixed' => CouponKind.fixed,
        'trial_extension' => CouponKind.trialExtension,
        _ => CouponKind.unknown,
      };

  static CouponReason reasonFromId(Object? id) => switch (id) {
        'expired' => CouponReason.expired,
        'not_applicable' => CouponReason.notApplicable,
        'exhausted' => CouponReason.exhausted,
        'already_used' => CouponReason.alreadyUsed,
        _ => CouponReason.invalid,
      };
}
