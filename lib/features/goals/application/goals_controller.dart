import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/goals/data/fake_goal_repository.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final GoalRepository repo = FakeGoalRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAll();
});

final goalActionsProvider = Provider<GoalActions>((ref) {
  return GoalActions(ref.watch(goalRepositoryProvider));
});

class GoalActions {
  GoalActions(this._repo);
  final GoalRepository _repo;

  Future<void> add(Goal g) => _repo.add(g);
  Future<void> update(Goal g) => _repo.update(g);
  Future<void> delete(String id) => _repo.delete(id);

  /// Adds a contribution to the goal's derived saved amount (never negative).
  Future<void> contribute(Goal g, Money amount) {
    final int next = g.saved.minorUnits + amount.minorUnits;
    return _repo.update(
      g.copyWith(saved: Money(next < 0 ? 0 : next, g.target.currencyCode)),
    );
  }

  static String newId() =>
      'goal-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
