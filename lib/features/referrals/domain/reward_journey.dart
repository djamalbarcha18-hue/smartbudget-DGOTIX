/// The rewards journey: every three friends who join and start using the app
/// earn the inviter one reward of their choice, up to all three.
///
/// Pure: the step a person is on, how many picks are waiting and how far the
/// next milestone is, from the count of activated friends and the rewards
/// already picked. The server decides (and checks) the picks; this is only
/// what the screen shows.
library;

import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

/// Where one step of the journey stands.
enum JourneyStepState {
  /// Reward picked: shown with its name.
  picked,

  /// Earned (the friends are there) but not picked yet: pick it now.
  pickable,

  /// Still ahead.
  locked,
}

class JourneyStep {
  const JourneyStep({
    required this.friends,
    required this.state,
    this.reward,
  });

  /// How many friends this step needs in total (3, 6, 9).
  final int friends;
  final JourneyStepState state;

  /// The reward picked on this step, when [state] is picked.
  final ReferralReward? reward;
}

class RewardJourney {
  const RewardJourney({required this.activated, required this.picked});

  /// Friends who joined through the link and started using the app.
  final int activated;

  /// The rewards picked so far, in the order they were picked.
  final List<ReferralReward> picked;

  static const RewardJourney none =
      RewardJourney(activated: 0, picked: <ReferralReward>[]);

  /// Friends needed for each pick.
  static const int friendsPerPick = ReferralRewards.needed;

  /// Picks there are in all: one per reward.
  static int get maxPicks => ReferralReward.values.length;

  /// Picks the friends so far have earned.
  int get picksEarned {
    final int n = activated ~/ friendsPerPick;
    return n > maxPicks ? maxPicks : n;
  }

  /// Picks still waiting to be used.
  int get picksAvailable {
    final int n = picksEarned - picked.length;
    return n < 0 ? 0 : n;
  }

  /// Every reward is picked: nothing is left to earn.
  bool get complete => picked.length >= maxPicks;

  /// Rewards still to pick, in their usual order.
  List<ReferralReward> get remaining => <ReferralReward>[
        for (final ReferralReward r in ReferralReward.values)
          if (!picked.contains(r)) r,
      ];

  /// The friend count of the next milestone: where the progress bar is
  /// heading (the last one once everything is earned).
  int get nextMilestone {
    final int step = picksEarned >= maxPicks ? maxPicks : picksEarned + 1;
    return step * friendsPerPick;
  }

  /// Friends still needed for the next pick after those already earned (0 when
  /// all are earned). A pick that is waiting is shown separately.
  int get friendsToNext {
    if (picksEarned >= maxPicks) return 0;
    final int left = nextMilestone - activated;
    return left < 0 ? 0 : left;
  }

  /// 0..1 inside the current stretch toward the next milestone.
  double get fractionToNext {
    if (picksEarned >= maxPicks) return 1;
    final int inStretch = activated - picksEarned * friendsPerPick;
    final double f = inStretch / friendsPerPick;
    return f < 0 ? 0 : (f > 1 ? 1 : f);
  }

  /// The three steps, in order.
  List<JourneyStep> get steps => <JourneyStep>[
        for (int i = 0; i < maxPicks; i++)
          JourneyStep(
            friends: (i + 1) * friendsPerPick,
            state: i < picked.length
                ? JourneyStepState.picked
                : i < picksEarned
                    ? JourneyStepState.pickable
                    : JourneyStepState.locked,
            reward: i < picked.length ? picked[i] : null,
          ),
      ];
}
