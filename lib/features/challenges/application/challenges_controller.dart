import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// What this user counts as side spending (their last choice): used for the
/// next challenge, the clean-day streaks and the badges.
final sideCategoriesProvider =
    NotifierProvider<SideCategoriesController, Set<String>>(
        SideCategoriesController.new);

class SideCategoriesController extends Notifier<Set<String>> {
  late String _key;

  @override
  Set<String> build() {
    final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
    _key = 'sb_side_categories_$userId';
    _load();
    return SideFree.defaultCategories;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null) return;
      final Set<String> saved = <String>{
        for (final dynamic c in jsonDecode(raw) as List<dynamic>) '$c',
      };
      if (saved.isNotEmpty) state = saved;
    } catch (_) {
      // Keep the defaults.
    }
  }

  Future<void> set(Set<String> categories) async {
    if (categories.isEmpty) return;
    state = Set<String>.unmodifiable(categories);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(categories.toList()));
    } catch (_) {
      // Non-fatal: the choice still applies this session.
    }
  }
}

final challengeActionsProvider =
    Provider<ChallengeActions>(ChallengeActions.new);

class ChallengeActions {
  ChallengeActions(this._ref);
  final Ref _ref;

  /// Starts a side-free challenge of [days] today.
  Future<void> start(int days, Set<String> categories) async {
    final DateTime n = AppClock.now();
    await _ref.read(sideCategoriesProvider.notifier).set(categories);
    await _ref.read(challengeStoreProvider).upsert(Challenge(
          id: 'ch-${n.microsecondsSinceEpoch.toRadixString(36)}',
          days: days,
          categories: categories,
          start: DateTime(n.year, n.month, n.day),
          createdAt: n,
        ));
  }

  Future<void> remove(String id) => _ref.read(challengeStoreProvider).delete(id);
}
