import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/challenges/domain/challenges.dart';

final challengeStoreProvider = Provider<LocalListStore<Challenge>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<Challenge> store = LocalListStore<Challenge>(
    key: 'sb_challenges_$userId',
    fromJson: Challenge.fromJson,
    toJson: (Challenge c) => c.toJson(),
    idOf: (Challenge c) => c.id,
    compare: (Challenge a, Challenge b) => b.start.compareTo(a.start),
  );
  ref.onDispose(store.dispose);
  return store;
});

final challengesProvider = StreamProvider<List<Challenge>>(
    (ref) => ref.watch(challengeStoreProvider).watchAll());

final challengeActionsProvider =
    Provider<ChallengeActions>(ChallengeActions.new);

class ChallengeActions {
  ChallengeActions(this._ref);
  final Ref _ref;

  Future<void> start(ChallengeType type) {
    final DateTime n = AppClock.now();
    return _ref.read(challengeStoreProvider).upsert(Challenge(
          id: 'ch-${n.microsecondsSinceEpoch.toRadixString(36)}',
          type: type,
          start: DateTime(n.year, n.month, n.day),
          createdAt: n,
        ));
  }

  Future<void> remove(String id) => _ref.read(challengeStoreProvider).delete(id);
}
