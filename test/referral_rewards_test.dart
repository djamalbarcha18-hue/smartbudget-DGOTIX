import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

const Set<ReferralReward> _all = <ReferralReward>{
  ReferralReward.salarySplit,
  ReferralReward.healthDetails,
  ReferralReward.higherLimits,
};

GateDecision _gate(Feature f,
        {Plan plan = Plan.free,
        Set<ReferralReward> rewards = const <ReferralReward>{},
        int used = 0}) =>
    FeatureGate.evaluate(f, plan: plan, used: used, rewards: rewards);

void main() {
  group('what inviting friends opens', () {
    test('the salary split and the health breakdown open on a free plan', () {
      for (final Feature f in <Feature>[
        Feature.salarySplit,
        Feature.healthDetails,
      ]) {
        expect(_gate(f).allowed, isFalse, reason: '$f before');
        expect(_gate(f, rewards: _all).allowed, isTrue, reason: '$f after');
      }
    });

    test('budgets stop being rationed', () {
      // The free allowance is five; the sixth is refused.
      expect(_gate(Feature.categoryBudgets, used: 5).allowed, isFalse);
      expect(_gate(Feature.categoryBudgets, used: 5, rewards: _all).allowed,
          isTrue);
      expect(_gate(Feature.categoryBudgets, used: 999, rewards: _all).allowed,
          isTrue,
          reason: 'unlimited, since this feeds "safe to spend today"');
    });

    test('the other counted features get more room, not unlimited', () {
      const Map<Feature, int> expected = <Feature, int>{
        Feature.goals: 5,
        Feature.debts: 5,
        Feature.wallets: 4,
        Feature.recurringRules: 10,
        Feature.darets: 3,
        Feature.seasons: 3,
      };
      expected.forEach((Feature f, int limit) {
        expect(_gate(f, used: limit - 1, rewards: _all).allowed, isTrue,
            reason: '$f below the new limit');
        expect(_gate(f, used: limit, rewards: _all).allowed, isFalse,
            reason: '$f at the new limit is still a limit');
      });
    });
  });

  group('what it must never open', () {
    test('nothing the server pays for', () {
      for (final Feature f in <Feature>[
        Feature.dgotixAi, // assistant requests cost money per call
        Feature.cloudOcr, // so does cloud receipt scanning
        Feature.cloudSyncFull, // storage and transfer
        Feature.parallelRates, // goes through our own function
        Feature.multiCurrency,
        Feature.prioritySupport, // costs the owner's time
      ]) {
        expect(ReferralRewards.opens(_all, f), isFalse, reason: '$f');
        expect(ReferralRewards.limitFor(_all, f), isNull, reason: '$f');
      }
    });

    test('not the reports, which are what PRO sells', () {
      for (final Feature f in <Feature>[
        Feature.advancedReports,
        Feature.reportTrends,
        Feature.smartAlerts,
      ]) {
        expect(_gate(f, rewards: _all).allowed, isFalse, reason: '$f');
      }
      // The PDF itself is free for everyone, invitations or not: what PRO
      // sells is the longer periods and the written analysis, both of which
      // sit behind Feature.advancedReports above.
      expect(_gate(Feature.reportPdf, rewards: _all).allowed, isTrue);
    });

    test('the AI allowance is untouched, with or without rewards', () {
      final GateDecision plain = _gate(Feature.dgotixAi, used: 1);
      final GateDecision earned =
          _gate(Feature.dgotixAi, used: 1, rewards: _all);
      expect(earned.limit, plain.limit);
      expect(earned.remaining, plain.remaining);
      // The free lifetime allowance is two: the third is refused either way.
      expect(_gate(Feature.dgotixAi, used: 2, rewards: _all).allowed, isFalse);
    });
  });

  group('rewards and subscriptions stay separate', () {
    test('a reward never shrinks what a plan already gives', () {
      // PRO has no limit on these; holding a reward must not impose one.
      for (final Feature f in <Feature>[
        Feature.goals,
        Feature.wallets,
        Feature.debts,
        Feature.recurringRules,
      ]) {
        expect(
            _gate(f, plan: Plan.pro, used: 500, rewards: _all).allowed, isTrue,
            reason: '$f on PRO');
      }
    });

    test('a reward does not make the account PRO', () {
      // It opens the two features it names and nothing else: cloud sync is
      // the test, because that one really does cost money.
      expect(_gate(Feature.cloudSyncFull, rewards: _all).allowed, isFalse);
    });
  });

  group('the reward list itself', () {
    test('ids match the ones the server grants', () {
      expect(ReferralReward.salarySplit.id, 'salary_split');
      expect(ReferralReward.healthDetails.id, 'health_details');
      expect(ReferralReward.higherLimits.id, 'higher_limits');
      expect(ReferralReward.byId('salary_split'), ReferralReward.salarySplit);
    });

    test('a reward from a newer server is ignored, not a crash', () {
      expect(ReferralReward.byId('something_new'), isNull);
    });

    test('three referrals earn it', () => expect(ReferralRewards.needed, 3));

    test('every reward names at least one feature', () {
      for (final ReferralReward r in ReferralReward.values) {
        expect(ReferralRewards.featuresOf(r), isNotEmpty, reason: '$r');
      }
    });
  });
}
