/// What inviting friends unlocks.
///
/// A reward is **not** a plan. It never raises a paid tier, never touches a
/// metered server feature (the assistant, cloud receipt scanning, sync), and
/// never costs DGOTIX anything to honour: every one of them is arithmetic the
/// device already does on data it already holds. That is deliberate — a
/// determined person can confirm three mailboxes of their own, and when they
/// do, what they gain costs nothing to give.
library;

import 'package:smartbudget/features/billing/domain/feature_catalog.dart';

/// The rewards the server can grant. The names match
/// `referral_rewards_for()` in supabase/referrals.sql; changing one means
/// changing both.
enum ReferralReward {
  /// The smart salary split, otherwise a PRO feature.
  salarySplit('salary_split'),

  /// Strengths, weaknesses and advice under the financial-health score,
  /// otherwise a PRO feature.
  healthDetails('health_details'),

  /// More of the things a free account is rationed on: budgets become
  /// unlimited, and goals, debts, wallets, recurring rules, darets and
  /// seasons each get more room.
  higherLimits('higher_limits');

  const ReferralReward(this.id);

  /// The identifier stored in `reward_grants.reward`.
  final String id;

  static ReferralReward? byId(String id) {
    for (final ReferralReward r in values) {
      if (r.id == id) return r;
    }
    return null; // A reward this build doesn't know about is simply ignored.
  }
}

/// How a set of granted rewards changes what a feature allows.
abstract final class ReferralRewards {
  /// How many referrals earn the set above.
  static const int needed = 3;

  /// Boolean gates a reward opens outright.
  static const Map<ReferralReward, Feature> _opens = <ReferralReward, Feature>{
    ReferralReward.salarySplit: Feature.salarySplit,
    ReferralReward.healthDetails: Feature.healthDetails,
  };

  /// The raised allowance for a counted feature, for someone holding
  /// [ReferralReward.higherLimits]. −1 means no limit.
  ///
  /// These sit above the free allowances in [FeatureCatalog] and below what
  /// PRO gives, so a reward never overtakes a subscription.
  static const Map<Feature, int> _raised = <Feature, int>{
    Feature.categoryBudgets: -1, // unlimited: this feeds "safe to spend today"
    Feature.goals: 5,
    Feature.debts: 5,
    Feature.wallets: 4,
    Feature.recurringRules: 10,
    Feature.darets: 3,
    Feature.seasons: 3,
  };

  /// The reward that opens [feature] outright (a locked one), or null.
  static ReferralReward? opensWith(Feature feature) {
    for (final MapEntry<ReferralReward, Feature> e in _opens.entries) {
      if (e.value == feature) return e.key;
    }
    return null;
  }

  /// Whether [rewards] open [feature] outright, regardless of plan.
  static bool opens(Set<ReferralReward> rewards, Feature feature) {
    for (final ReferralReward r in rewards) {
      if (_opens[r] == feature) return true;
    }
    return false;
  }

  /// The allowance [rewards] give for [feature], or null when they say
  /// nothing about it. The caller keeps whichever is larger — the plan's or
  /// this — so a reward can only ever add room, never take it away.
  static int? limitFor(Set<ReferralReward> rewards, Feature feature) =>
      rewards.contains(ReferralReward.higherLimits) ? _raised[feature] : null;

  /// Every feature a reward touches, for the "what you unlocked" list.
  static List<Feature> featuresOf(ReferralReward reward) =>
      reward == ReferralReward.higherLimits
          ? _raised.keys.toList()
          : <Feature>[if (_opens[reward] case final Feature f) f];
}
