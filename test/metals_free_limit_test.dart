import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

void main() {
  test('gold is free; the other metals are PRO only', () {
    // Gold has no gate of its own; the gate is on "the other metals".
    expect(FeatureCatalog.minTierFor(Feature.metals), Plan.pro);
    expect(FeatureGate.evaluate(Feature.metals, plan: Plan.free).allowed,
        isFalse);
    expect(FeatureGate.evaluate(Feature.metals, plan: Plan.pro).allowed,
        isTrue);
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
    for (final Feature f in <Feature>[Feature.metals, Feature.metalsAdvanced]) {
      expect(ReferralRewards.limitFor(all, f), isNull);
      expect(ReferralRewards.opensWith(f), isNull);
      expect(ReferralRewards.opens(all, f), isFalse);
      expect(FeatureGate.evaluate(f, plan: Plan.free, rewards: all).allowed,
          isFalse);
    }
  });
}
