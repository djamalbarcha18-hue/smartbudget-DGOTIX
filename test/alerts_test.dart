import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

const String usd = 'USD';
final DateTime now = DateTime(2026, 6, 1);

FinanceSummary _summary({int income = 0, int expense = 0, int count = 0}) {
  final int net = income - expense;
  return FinanceSummary(
    income: Money(income, usd),
    expense: Money(expense, usd),
    net: Money(net, usd),
    savingsRate: income == 0 ? 0 : net / income,
    count: count,
  );
}

void main() {
  group('AlertEngine budgets', () {
    test('over budget → high severity alert with the overspend', () {
      final List<AppAlert> a = AlertEngine.build(
        plannedByCategory: <String, int>{'الطعام': 10000},
        actualByCategory: <String, int>{'الطعام': 13000},
        goals: const <Goal>[],
        yearSummary: _summary(),
        currency: usd,
        now: now,
      );
      expect(a, hasLength(1));
      expect(a.first.kind, AlertKind.budgetOver);
      expect(a.first.severity, AlertSeverity.high);
      expect(a.first.amount.minorUnits, 3000);
    });

    test('at 90%+ of budget → medium "near" alert with remaining', () {
      final List<AppAlert> a = AlertEngine.build(
        plannedByCategory: <String, int>{'النقل': 1000},
        actualByCategory: <String, int>{'النقل': 950},
        goals: const <Goal>[],
        yearSummary: _summary(),
        currency: usd,
        now: now,
      );
      expect(a.single.kind, AlertKind.budgetNear);
      expect(a.single.amount.minorUnits, 50);
    });

    test('comfortably under budget → no alert', () {
      final List<AppAlert> a = AlertEngine.build(
        plannedByCategory: <String, int>{'النقل': 1000},
        actualByCategory: <String, int>{'النقل': 400},
        goals: const <Goal>[],
        yearSummary: _summary(),
        currency: usd,
        now: now,
      );
      expect(a, isEmpty);
    });
  });

  group('AlertEngine cash-flow', () {
    test('negative net → high alert; nothing without data', () {
      expect(
        AlertEngine.build(
          plannedByCategory: const <String, int>{},
          actualByCategory: const <String, int>{},
          goals: const <Goal>[],
          yearSummary: _summary(income: 1000, expense: 1500, count: 3),
          currency: usd,
          now: now,
        ).single.kind,
        AlertKind.netNegative,
      );
      expect(
        AlertEngine.build(
          plannedByCategory: const <String, int>{},
          actualByCategory: const <String, int>{},
          goals: const <Goal>[],
          yearSummary: _summary(), // count 0
          currency: usd,
          now: now,
        ),
        isEmpty,
      );
    });

    test('positive but thin savings → low-savings alert', () {
      final List<AppAlert> a = AlertEngine.build(
        plannedByCategory: const <String, int>{},
        actualByCategory: const <String, int>{},
        goals: const <Goal>[],
        yearSummary: _summary(income: 1000, expense: 950, count: 3), // 5%
        currency: usd,
        now: now,
      );
      expect(a.single.kind, AlertKind.savingsLow);
    });
  });

  group('AlertEngine goals', () {
    Goal g(String id, DateTime? deadline, {int target = 1000, int saved = 0}) =>
        Goal(
          id: id,
          name: id,
          target: Money(target, usd),
          saved: Money(saved, usd),
          deadline: deadline,
          createdAt: now,
        );

    test('overdue goal (past date, unfinished) → high alert', () {
      expect(
        AlertEngine.build(
          plannedByCategory: const <String, int>{},
          actualByCategory: const <String, int>{},
          goals: <Goal>[g('trip', DateTime(2026, 3, 1))],
          yearSummary: _summary(),
          currency: usd,
          now: now,
        ).single.kind,
        AlertKind.goalOverdue,
      );
    });

    test('goal within 6 months → urgent; completed goal → no alert', () {
      final List<AppAlert> urgent = AlertEngine.build(
        plannedByCategory: const <String, int>{},
        actualByCategory: const <String, int>{},
        goals: <Goal>[g('car', DateTime(2026, 10, 1))],
        yearSummary: _summary(),
        currency: usd,
        now: now,
      );
      expect(urgent.single.kind, AlertKind.goalUrgent);

      final List<AppAlert> done = AlertEngine.build(
        plannedByCategory: const <String, int>{},
        actualByCategory: const <String, int>{},
        goals: <Goal>[g('done', DateTime(2026, 3, 1), target: 1000, saved: 1000)],
        yearSummary: _summary(),
        currency: usd,
        now: now,
      );
      expect(done, isEmpty);
    });
  });
}
