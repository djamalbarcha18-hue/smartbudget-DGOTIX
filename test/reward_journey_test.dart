import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/domain/reward_journey.dart';

RewardJourney j(int n, [List<ReferralReward> picked = const <ReferralReward>[]]) =>
    RewardJourney(activated: n, picked: picked);

void main() {
  test('one pick for every three friends, never more than the rewards', () {
    expect(<int>[0, 1, 2, 3, 5, 6, 8, 9, 30].map((int n) => j(n).picksEarned),
        <int>[0, 0, 0, 1, 1, 2, 2, 3, 3]);
  });

  test('picks waiting = earned minus used', () {
    expect(j(3).picksAvailable, 1);
    expect(j(3, <ReferralReward>[ReferralReward.higherLimits]).picksAvailable,
        0);
    expect(j(7, <ReferralReward>[ReferralReward.salarySplit]).picksAvailable,
        1);
  });

  test('the next milestone and what is left to reach it', () {
    expect(j(0).nextMilestone, 3);
    expect(j(2).friendsToNext, 1);
    expect(j(4, <ReferralReward>[ReferralReward.higherLimits]).nextMilestone,
        6);
    expect(j(4, <ReferralReward>[ReferralReward.higherLimits]).friendsToNext,
        2);
    // A pick is waiting (shown apart); the bar starts again toward six.
    expect(j(3).picksAvailable, 1);
    expect(j(3).nextMilestone, 6);
    expect(j(3).friendsToNext, 3);
    expect(j(3).fractionToNext, 0);
    expect(j(1).fractionToNext, closeTo(1 / 3, 1e-9));
    // Everything earned: the bar stays full on the last milestone.
    expect(j(12).nextMilestone, 9);
    expect(j(12).fractionToNext, 1);
  });

  test('the three steps show picked, pickable and locked in order', () {
    final List<JourneyStep> s =
        j(7, <ReferralReward>[ReferralReward.salarySplit]).steps;
    expect(s.map((JourneyStep e) => e.friends), <int>[3, 6, 9]);
    expect(s.map((JourneyStep e) => e.state), <JourneyStepState>[
      JourneyStepState.picked,
      JourneyStepState.pickable,
      JourneyStepState.locked,
    ]);
    expect(s.first.reward, ReferralReward.salarySplit);
  });

  test('what is left to pick, and when it is all done', () {
    final RewardJourney done = j(9, ReferralReward.values);
    expect(done.complete, isTrue);
    expect(done.remaining, isEmpty);
    expect(
        j(3, <ReferralReward>[ReferralReward.healthDetails]).remaining,
        <ReferralReward>[
          ReferralReward.salarySplit,
          ReferralReward.higherLimits,
        ]);
  });

  test('the milestones match the server: one pick per three', () {
    expect(RewardJourney.friendsPerPick, 3);
    expect(RewardJourney.maxPicks, 3);
  });
}
