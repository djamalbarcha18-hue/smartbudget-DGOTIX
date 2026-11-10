/// Providers for the invite screen and for the gate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/domain/reward_journey.dart';

/// The signed-in account, so every provider below re-reads when it changes
/// (signing out must not leave another account's rewards on screen).
String? _uid(Ref ref) => ref.watch(authControllerProvider).user?.id;

/// This member's invite code. Null while loading, signed out, or offline.
final referralCodeProvider = FutureProvider<String?>((Ref ref) async {
  if (_uid(ref) == null) return null;
  return ref.watch(referralServiceProvider).code();
});

/// How many invited people have joined and started using the app.
final referralProgressProvider =
    FutureProvider<ReferralProgress>((Ref ref) async {
  if (_uid(ref) == null) return ReferralProgress.none;
  return ref.watch(referralServiceProvider).progress();
});

/// The rewards the server says this account holds.
final referralGrantsProvider =
    FutureProvider<Set<ReferralReward>>((Ref ref) async {
  if (_uid(ref) == null) return const <ReferralReward>{};
  return ref.watch(referralServiceProvider).grants();
});

/// When the invited member got the welcome gift (null: none).
final welcomeGiftProvider = FutureProvider<DateTime?>((Ref ref) async {
  if (_uid(ref) == null) return null;
  return ref.watch(referralServiceProvider).welcomeGiftGrantedAt();
});

/// The rewards in force right now, for the feature gate: the picks, plus the
/// smart salary split while the welcome gift runs.
///
/// Synchronous and never null: while the answer is in flight, or when it
/// failed, this is empty — which withholds the extras and changes nothing
/// else. A reward only ever adds, so an empty set is always the safe guess.
final activeRewardsProvider = Provider<Set<ReferralReward>>((Ref ref) {
  final Set<ReferralReward> picks =
      ref.watch(referralGrantsProvider).valueOrNull ??
          const <ReferralReward>{};
  final DateTime? gift = ref.watch(welcomeGiftProvider).valueOrNull;
  if (ReferralRewards.welcomeGiftActive(gift, AppClock.now())) {
    return <ReferralReward>{...picks, ReferralReward.salarySplit};
  }
  return picks;
});

/// Where this member stands on the rewards journey: friends so far and what
/// has been picked. While the answers are in flight it is the start (nothing
/// earned), which withholds, never grants.
final rewardJourneyProvider = Provider<RewardJourney>((Ref ref) {
  final ReferralProgress progress =
      ref.watch(referralProgressProvider).valueOrNull ?? ReferralProgress.none;
  final Set<ReferralReward> grants = ref.watch(referralGrantsProvider)
          .valueOrNull ??
      const <ReferralReward>{};
  return RewardJourney(
      activated: progress.activated,
      picked: grants.toList(growable: false));
});

/// Uses a pick on [reward]. True when the server granted it; the grants are
/// read again so the gates open at once.
Future<bool> chooseReward(WidgetRef ref, ReferralReward reward) async {
  final bool ok = await ref.read(referralServiceProvider).choose(reward);
  if (ok) ref.invalidate(referralGrantsProvider);
  return ok;
}
