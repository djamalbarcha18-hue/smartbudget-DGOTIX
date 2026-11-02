/// Providers for the invite screen and for the gate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';

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

/// The rewards in force right now, for the feature gate.
///
/// Synchronous and never null: while the answer is in flight, or when it
/// failed, this is empty — which withholds the extras and changes nothing
/// else. A reward only ever adds, so an empty set is always the safe guess.
final activeRewardsProvider = Provider<Set<ReferralReward>>(
  (Ref ref) =>
      ref.watch(referralGrantsProvider).valueOrNull ?? const <ReferralReward>{},
);
