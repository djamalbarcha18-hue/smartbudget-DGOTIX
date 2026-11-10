import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

void main() {
  // Dates relative to now, as the app's own clock is the device clock here.
  final DateTime day0 = DateTime.now().subtract(const Duration(days: 5));
  final DateTime old = DateTime.now().subtract(const Duration(days: 40));

  test('the welcome gift lasts 30 days from the day it was given', () {
    expect(ReferralRewards.welcomeGiftDays, 30);
    final DateTime given = DateTime(2026, 11, 1);
    expect(ReferralRewards.welcomeGiftEnds(given), DateTime(2026, 12, 1));
    expect(ReferralRewards.welcomeGiftEnds(null), isNull);
    expect(ReferralRewards.welcomeGiftActive(given, DateTime(2026, 11, 30)),
        isTrue);
    expect(ReferralRewards.welcomeGiftActive(given, DateTime(2026, 12, 2)),
        isFalse);
    expect(ReferralRewards.welcomeGiftActive(null, given), isFalse);
  });

  test('while it runs the salary split is open, nothing else is', () {
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      referralGrantsProvider
          .overrideWith((_) async => const <ReferralReward>{}),
      welcomeGiftProvider.overrideWith((_) async => day0),
    ]);
    addTearDown(c.dispose);
    return Future<void>(() async {
      await c.read(referralGrantsProvider.future);
      await c.read(welcomeGiftProvider.future);
      final Set<ReferralReward> rewards = c.read(activeRewardsProvider);
      expect(rewards, <ReferralReward>{ReferralReward.salarySplit});
      expect(
          FeatureGate.evaluate(Feature.salarySplit,
                  plan: Plan.free, rewards: rewards)
              .allowed,
          isTrue);
      // The health details and the limits are still earned the usual way.
      expect(
          FeatureGate.evaluate(Feature.healthDetails,
                  plan: Plan.free, rewards: rewards)
              .allowed,
          isFalse);
      expect(
          FeatureGate.evaluate(Feature.goals,
                  plan: Plan.free, used: 2, rewards: rewards)
              .allowed,
          isFalse);
    });
  });

  test('after it ends the salary split is closed again', () async {
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      referralGrantsProvider
          .overrideWith((_) async => const <ReferralReward>{}),
      welcomeGiftProvider.overrideWith((_) async => old),
    ]);
    addTearDown(c.dispose);
    await c.read(referralGrantsProvider.future);
    await c.read(welcomeGiftProvider.future);
    expect(c.read(activeRewardsProvider), isEmpty);
  });

  test('a pick and the gift together never exceed what the picks allow',
      () async {
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      referralGrantsProvider
          .overrideWith((_) async => <ReferralReward>{ReferralReward.higherLimits}),
      welcomeGiftProvider.overrideWith((_) async => day0),
    ]);
    addTearDown(c.dispose);
    await c.read(referralGrantsProvider.future);
    await c.read(welcomeGiftProvider.future);
    expect(c.read(activeRewardsProvider), <ReferralReward>{
      ReferralReward.higherLimits,
      ReferralReward.salarySplit,
    });
    // The journey counts picks only: the gift is not one of them.
    expect(c.read(rewardJourneyProvider).picked,
        <ReferralReward>[ReferralReward.higherLimits]);
  });
}
