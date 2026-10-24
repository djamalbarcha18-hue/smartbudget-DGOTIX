import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';

void main() {
  final DateTime now = DateTime(2026, 6, 15);

  Goal goal(String id, {DateTime? deadline, ProjectHorizon? horizon}) => Goal(
        id: id,
        name: 'Goal $id',
        target: const Money(500000, 'USD'),
        saved: const Money(100000, 'USD'),
        deadline: deadline,
        createdAt: DateTime(2026),
        horizon: horizon,
      );

  group('one list: the funding plan reads the financial goals', () {
    test('the horizon follows the deadline unless the user chose one', () {
      expect(
          Project.fromGoal(goal('a', deadline: DateTime(2027, 3)), now).horizon,
          ProjectHorizon.near);
      expect(
          Project.fromGoal(goal('b', deadline: DateTime(2028, 6)), now).horizon,
          ProjectHorizon.mid);
      expect(Project.fromGoal(goal('c', deadline: DateTime(2031)), now).horizon,
          ProjectHorizon.long);
      expect(Project.fromGoal(goal('d'), now).horizon, ProjectHorizon.mid);
      expect(
          Project.fromGoal(
                  goal('e',
                      deadline: DateTime(2031), horizon: ProjectHorizon.near),
                  now)
              .horizon,
          ProjectHorizon.near);
    });

    test('a goal through the plan and back is the same goal', () {
      final Goal g =
          goal('a', deadline: DateTime(2028), horizon: ProjectHorizon.long);
      final Goal back = Project.fromGoal(g, now).toGoal();
      expect(back.toJson(), g.toJson());
      expect(Goal.fromJson(g.toJson()).horizon, ProjectHorizon.long);
      expect(Goal.fromJson(goal('b').toJson()).horizon, isNull);
    });

    test('added in the plan: a goal; projects saved before move into goals',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(goalsProvider.future);
      // Something saved the old way, before the plan read the goals.
      await c.read(projectRepositoryProvider).add(Project(
            id: 'proj-1',
            name: 'Open a shop',
            target: const Money(800000, 'USD'),
            saved: const Money(50000, 'USD'),
            horizon: ProjectHorizon.long,
            createdAt: DateTime(2026),
          ));
      await c
          .read(projectActionsProvider)
          .add(Project.fromGoal(goal('g1'), now));
      // The plan moves the old project over, once.
      c.listen(planProjectsProvider, (_, __) {});
      for (int i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final List<Goal> goals = c.read(goalRepositoryProvider).current;
      expect(
          goals.map((Goal g) => g.id), containsAll(<String>['g1', 'proj-1']));
      expect(goals.firstWhere((Goal g) => g.id == 'proj-1').horizon,
          ProjectHorizon.long);
      expect(c.read(projectRepositoryProvider).current, isEmpty);
      expect(c.read(planProjectsProvider).length, 2);
    });

    test('a payment from the plan adds to the goal', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(goalsProvider, (_, __) {});
      await c.read(goalActionsProvider).add(goal('g1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final Project p = c.read(planProjectsProvider).single;
      await c
          .read(projectActionsProvider)
          .contribute(p, const Money(25000, 'USD'));
      final Goal after = c.read(goalRepositoryProvider).current.single;
      expect(after.saved, const Money(125000, 'USD'));
      expect(after.horizon, isNull); // still follows its deadline
    });
  });
}
