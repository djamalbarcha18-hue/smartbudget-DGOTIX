import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/assistant/application/ai_usage_controller.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// Client-side used-count for a metered [Feature] this period.
///
/// This is the best on-device signal for nudges/CTAs; the **server remains the
/// real enforcer**. Non-metered features return 0 (ignored by the gate). OCR
/// has no on-device counter yet, so it reports 0 until one is wired — the
/// server still enforces its quota regardless.
int _usedFor(Ref ref, Feature f) {
  switch (f) {
    case Feature.dgotixAi:
      return ref.watch(aiUsageMonthProvider).requests;
    case Feature.cloudOcr:
    case Feature.advancedReports:
    case Feature.cloudSyncFull:
    case Feature.portfolioFull:
    case Feature.prioritySupport:
    case Feature.salarySplit:
    case Feature.smartAlerts:
      return 0;
  }
}

/// The live [GateDecision] for a feature, given the in-force plan and current
/// usage. Widgets watch this instead of branching on the plan themselves.
final featureGateProvider = Provider.family<GateDecision, Feature>((ref, f) {
  final Plan plan = ref.watch(effectivePlanProvider);
  return FeatureGate.evaluate(f,
      plan: plan,
      used: _usedFor(ref, f),
      period: ref.watch(billingPeriodProvider));
});
