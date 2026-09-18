import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';

const String usd = 'USD';

Goal _goal({
  required double target,
  double saved = 0,
  DateTime? deadline,
}) {
  return Goal(
    id: 'g-${target.hashCode}-${saved.hashCode}',
    name: 'Goal',
    target: Money.fromDouble(target, usd),
    saved: Money.fromDouble(saved, usd),
    deadline: deadline,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final DateTime now = DateTime(2026, 1, 1);

  group('GoalCalculator.progress & status', () {
    test('progress = saved / target', () {
      expect(GoalCalculator.progress(_goal(target: 1000, saved: 250)),
          closeTo(0.25, 1e-9));
    });

    test('zero target yields 0 (no divide-by-zero)', () {
      expect(GoalCalculator.progress(_goal(target: 0, saved: 100)), 0);
    });

    test('status thresholds: completed / saving / notStarted', () {
      expect(GoalCalculator.status(_goal(target: 100, saved: 100)),
          GoalStatus.completed);
      expect(GoalCalculator.status(_goal(target: 100, saved: 50)),
          GoalStatus.saving);
      expect(GoalCalculator.status(_goal(target: 100, saved: 0)),
          GoalStatus.notStarted);
    });
  });

  group('GoalCalculator.monthsRemaining & installment', () {
    test('months between now and deadline (>= 0)', () {
      expect(
        GoalCalculator.monthsRemaining(
            _goal(target: 100, deadline: DateTime(2026, 7, 1)),
            now: now),
        6,
      );
      expect(
        GoalCalculator.monthsRemaining(
            _goal(target: 100, deadline: DateTime(2025, 1, 1)),
            now: now),
        0,
      );
    });

    test('installment = remaining / monthsRemaining', () {
      final Goal g = _goal(target: 1000, saved: 400, deadline: DateTime(2026, 7, 1));
      // remaining 600 over 6 months = 100/month.
      expect(GoalCalculator.monthlyInstallment(g, now: now),
          Money.fromDouble(100, usd));
    });

    test('installment is 0 once the target is reached', () {
      final Goal g = _goal(target: 500, saved: 500, deadline: DateTime(2026, 7, 1));
      expect(GoalCalculator.monthlyInstallment(g, now: now).isZero, isTrue);
    });
  });

  group('GoalCalculator.urgency', () {
    test('tiers by horizon', () {
      expect(
        GoalCalculator.urgency(
            _goal(target: 100, saved: 10, deadline: DateTime(2029, 1, 1)),
            now: now),
        GoalUrgency.relaxed,
      );
      expect(
        GoalCalculator.urgency(
            _goal(target: 100, saved: 10, deadline: DateTime(2026, 6, 1)),
            now: now),
        GoalUrgency.urgent,
      );
      expect(
        GoalCalculator.urgency(_goal(target: 100, saved: 100), now: now),
        GoalUrgency.achieved,
      );
    });
  });
}
