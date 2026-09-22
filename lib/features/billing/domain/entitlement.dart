/// Entitlement — what the account is currently entitled to.
///
/// The **server is the source of truth**; this value object is what the client
/// holds (hydrated from the server when signed in, or a local FREE default
/// otherwise). It combines the paid [plan] with an optional time-boxed trial so
/// a lapsed trial silently falls back to the paid plan with no data loss.
library;

import 'package:smartbudget/features/billing/domain/plan.dart';

class Entitlement {
  const Entitlement({
    this.plan = Plan.free,
    this.trialPlan,
    this.trialExpiresAt,
  });

  /// The account's own (paid or free) plan.
  final Plan plan;

  /// A temporarily granted higher plan (e.g. a PRO trial), or null.
  final Plan? trialPlan;

  /// When [trialPlan] stops applying. Null when there is no trial.
  final DateTime? trialExpiresAt;

  /// A permanently-free default (used before the server answers / when signed
  /// out). Never a paid plan, so nothing is unlocked without server truth.
  static const Entitlement free = Entitlement();

  bool trialActiveAt(DateTime now) =>
      trialPlan != null &&
      trialExpiresAt != null &&
      now.isBefore(trialExpiresAt!);

  /// The plan actually in force now: the higher of [plan] and an active trial.
  Plan effectivePlanAt(DateTime now) {
    if (trialActiveAt(now) && trialPlan!.atLeast(plan)) return trialPlan!;
    return plan;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plan': plan.storageId,
        if (trialPlan != null) 'trialPlan': trialPlan!.storageId,
        if (trialExpiresAt != null)
          'trialExpiresAt': trialExpiresAt!.toUtc().toIso8601String(),
      };

  static Entitlement fromJson(Map<String, dynamic> j) {
    final String? tp = j['trialPlan'] as String?;
    final String? te = j['trialExpiresAt'] as String?;
    return Entitlement(
      plan: PlanX.fromStorage(j['plan'] as String?),
      trialPlan: tp == null ? null : PlanX.fromStorage(tp),
      trialExpiresAt: te == null ? null : DateTime.tryParse(te),
    );
  }

  Entitlement copyWith({
    Plan? plan,
    Plan? trialPlan,
    DateTime? trialExpiresAt,
  }) =>
      Entitlement(
        plan: plan ?? this.plan,
        trialPlan: trialPlan ?? this.trialPlan,
        trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      );
}
