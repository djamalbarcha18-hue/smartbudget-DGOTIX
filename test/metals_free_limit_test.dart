import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

void main() {
  test('FREE follows one kind of metal, PRO any number', () {
    expect(FeatureCatalog.quotaFor(Feature.metals, Plan.free)?.limit, 1);
    expect(FeatureCatalog.quotaFor(Feature.metals, Plan.pro)?.isUnlimited,
        isTrue);
    expect(FeatureGate.evaluate(Feature.metals, plan: Plan.free, used: 0)
        .allowed, isTrue);
    final GateDecision d =
        FeatureGate.evaluate(Feature.metals, plan: Plan.free, used: 1);
    expect(d.allowed, isFalse);
    expect(d.reason, GateReason.quotaReached);
    expect(FeatureGate.evaluate(Feature.metals, plan: Plan.pro, used: 9)
        .allowed, isTrue);
  });

  test('alerts, value history and sales are PRO only', () {
    expect(FeatureCatalog.minTierFor(Feature.metalsAdvanced), Plan.pro);
    expect(FeatureGate.evaluate(Feature.metalsAdvanced, plan: Plan.free)
        .allowed, isFalse);
    expect(FeatureGate.evaluate(Feature.metalsAdvanced, plan: Plan.pro)
        .allowed, isTrue);
  });

  test('inviting friends does not open any of it', () {
    const Set<ReferralReward> all = <ReferralReward>{
      ReferralReward.higherLimits,
      ReferralReward.salarySplit,
      ReferralReward.healthDetails,
    };
    expect(ReferralRewards.limitFor(all, Feature.metals), isNull);
    expect(ReferralRewards.opensWith(Feature.metals), isNull);
    expect(ReferralRewards.opensWith(Feature.metalsAdvanced), isNull);
    expect(ReferralRewards.opens(all, Feature.metalsAdvanced), isFalse);
    expect(
        FeatureGate.evaluate(Feature.metals,
            plan: Plan.free, used: 1, rewards: all).allowed,
        isFalse);
  });
}
