import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/reports/domain/report_range.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String _cur = 'DZD';

Money _m(int major) => Money(major * 100, _cur);

Transaction _t({
  required int year,
  required int month,
  required int major,
  required TransactionType type,
  String category = 'طعام',
  String currency = _cur,
}) =>
    Transaction(
      id: '$year-$month-$major-${type.name}-$category',
      date: DateTime(year, month, 15),
      category: category,
      amount: Money(major * 100, currency),
      type: type,
      createdAt: DateTime(year, month, 15),
    );

BudgetTarget _b(int year, int month, String category, int major) =>
    BudgetTarget(
      id: '$year-$month-$category',
      year: year,
      month: month,
      category: category,
      planned: _m(major),
      createdAt: DateTime(year, month, 1),
    );

ReportRange _range(ReportPeriod p, int year, int sub) =>
    ReportRange(period: p, year: year, sub: sub);

void main() {
  group('the range before this one', () {
    test('January reaches back into last December', () {
      final ReportRange jan = _range(ReportPeriod.monthly, 2026, 1);
      expect(jan.previous, _range(ReportPeriod.monthly, 2025, 12));
    });

    test('Q1 reaches back to Q4, the first half to the second', () {
      expect(_range(ReportPeriod.quarterly, 2026, 1).previous,
          _range(ReportPeriod.quarterly, 2025, 4));
      expect(_range(ReportPeriod.halfYearly, 2026, 1).previous,
          _range(ReportPeriod.halfYearly, 2025, 2));
      expect(_range(ReportPeriod.yearly, 2026, 1).previous,
          _range(ReportPeriod.yearly, 2025, 1));
    });

    test('inside a year it is simply the one before', () {
      expect(_range(ReportPeriod.monthly, 2026, 7).previous,
          _range(ReportPeriod.monthly, 2026, 6));
      expect(_range(ReportPeriod.quarterly, 2026, 3).previous,
          _range(ReportPeriod.quarterly, 2026, 2));
    });

    test('a range holds only its own months', () {
      final ReportRange q2 = _range(ReportPeriod.quarterly, 2026, 2);
      expect(q2.contains(DateTime(2026, 4, 1)), isTrue);
      expect(q2.contains(DateTime(2026, 6, 30)), isTrue);
      expect(q2.contains(DateTime(2026, 7, 1)), isFalse);
      expect(q2.contains(DateTime(2025, 5, 1)), isFalse,
          reason: 'same month, wrong year');
    });
  });

  group('the figures', () {
    final List<Transaction> txns = <Transaction>[
      // December 2025 — the month before January's report.
      _t(
          year: 2025,
          month: 12,
          major: 60000,
          type: TransactionType.income,
          category: 'راتب'),
      _t(year: 2025, month: 12, major: 50000, type: TransactionType.expense),
      // January 2026.
      _t(
          year: 2026,
          month: 1,
          major: 80000,
          type: TransactionType.income,
          category: 'راتب'),
      _t(
          year: 2026,
          month: 1,
          major: 30000,
          type: TransactionType.expense,
          category: 'إيجار السكن'),
      _t(year: 2026, month: 1, major: 20000, type: TransactionType.expense),
      // March 2026, outside January's range.
      _t(year: 2026, month: 3, major: 9000, type: TransactionType.expense),
    ];

    ReportFigures figures({
      List<BudgetTarget> budgets = const <BudgetTarget>[],
      ReportRange? range,
    }) =>
        ReportFigures.build(
          range: range ?? _range(ReportPeriod.monthly, 2026, 1),
          currency: _cur,
          transactions: txns,
          budgets: budgets,
        );

    test('counts only the months of its own range', () {
      final ReportFigures f = figures();
      expect(f.summary.income, _m(80000));
      expect(f.summary.expense, _m(50000));
      expect(f.summary.net, _m(30000));
      expect(f.expenses.length, 2, reason: 'March is not in January');
    });

    test('compares January with last December, across the year line', () {
      final ReportFigures f = figures();
      expect(f.hasComparison, isTrue);
      expect(f.previous!.income, _m(60000));
      expect(f.incomeChange!.delta, _m(20000));
      expect(f.incomeChange!.ratio, closeTo(1 / 3, 1e-9));
      expect(f.expenseChange!.delta, _m(0));
      expect(f.expenseChange!.isFlat, isTrue);
      expect(f.netChange!.delta, _m(20000));
      expect(f.savingsRateChange, closeTo(0.375 - (1 / 6), 1e-9));
    });

    test('a period with nothing before it says so instead of guessing', () {
      final ReportFigures f =
          figures(range: _range(ReportPeriod.monthly, 2025, 12));
      expect(f.hasComparison, isFalse);
      expect(f.incomeChange, isNull);
      expect(f.netChange, isNull);
      expect(f.savingsRateChange, isNull);
    });

    test('a move from zero has no percentage to report', () {
      const PeriodChange fromZero =
          PeriodChange(now: Money(5000, _cur), before: Money(0, _cur));
      expect(fromZero.ratio, isNull);
      expect(fromZero.delta, const Money(5000, _cur));
      expect(fromZero.isUp, isTrue);
    });

    test('the year series is the whole year, whatever the period', () {
      final ReportFigures f = figures();
      expect(f.year.length, 12);
      expect(f.year[0].income, _m(80000), reason: 'January');
      expect(f.year[2].expense, _m(9000), reason: 'March is still charted');
      expect(f.year[11].income, _m(0), reason: 'December 2025 is another year');
    });
  });

  group('the budget side', () {
    final List<Transaction> txns = <Transaction>[
      _t(
          year: 2026,
          month: 1,
          major: 26000,
          type: TransactionType.expense,
          category: 'إيجار السكن'),
      _t(
          year: 2026,
          month: 1,
          major: 7000,
          type: TransactionType.expense,
          category: 'طعام'),
      _t(
          year: 2026,
          month: 1,
          major: 4000,
          type: TransactionType.expense,
          category: 'هدايا'),
    ];

    BudgetFigures budgetFor(List<BudgetTarget> budgets, {int sub = 1}) =>
        ReportFigures.build(
          range: _range(ReportPeriod.monthly, 2026, sub),
          currency: _cur,
          transactions: txns,
          budgets: budgets,
        ).budget;

    test('plan and spending are measured on the same categories', () {
      final BudgetFigures b = budgetFor(<BudgetTarget>[
        _b(2026, 1, 'إيجار السكن', 25000),
        _b(2026, 1, 'طعام', 10000),
      ]);
      expect(b.planned, _m(35000));
      // 26000 + 7000. The 4000 on هدايا has no plan, so it is not counted
      // against one.
      expect(b.spent, _m(33000));
      expect(b.remaining, _m(2000));
      expect(b.categories, 2);
      expect(b.isOver, isFalse);
      expect(b.used, closeTo(33000 / 35000, 1e-9));
    });

    test('overspending is reported as overspending', () {
      final BudgetFigures b =
          budgetFor(<BudgetTarget>[_b(2026, 1, 'إيجار السكن', 20000)]);
      expect(b.isOver, isTrue);
      expect(b.remaining.minorUnits, lessThan(0));
    });

    test('no budget at all is a clean absence, not a zero-divide', () {
      final BudgetFigures b = budgetFor(const <BudgetTarget>[]);
      expect(b.hasBudget, isFalse);
      expect(b.used, isNull);
      expect(b.isOver, isFalse);
      expect(b.planned, _m(0));
    });

    test('a plan for another month is not this month\'s plan', () {
      final BudgetFigures b = budgetFor(<BudgetTarget>[
        _b(2026, 2, 'إيجار السكن', 25000),
      ]);
      expect(b.hasBudget, isFalse);
    });

    test('a quarter adds up its three months of plans', () {
      final BudgetFigures b = ReportFigures.build(
        range: _range(ReportPeriod.quarterly, 2026, 1),
        currency: _cur,
        transactions: txns,
        budgets: <BudgetTarget>[
          _b(2026, 1, 'طعام', 10000),
          _b(2026, 2, 'طعام', 10000),
          _b(2026, 3, 'طعام', 10000),
        ],
      ).budget;
      expect(b.planned, _m(30000));
      expect(b.categories, 1);
    });
  });

  group('what travels alongside', () {
    test('debts and the health score are carried, not recomputed', () {
      const DebtSummary debts = DebtSummary(
        owedToMe: Money(100000, _cur),
        owedByMe: Money(250000, _cur),
        net: Money(-150000, _cur),
        openCount: 3,
      );
      final ReportFigures f = ReportFigures.build(
        range: _range(ReportPeriod.monthly, 2026, 1),
        currency: _cur,
        transactions: const <Transaction>[],
        budgets: const <BudgetTarget>[],
        debts: debts,
        healthScore: 72.5,
      );
      expect(f.debts, same(debts));
      expect(f.healthScore, 72.5);
    });

    test('an empty period still produces a whole document', () {
      final ReportFigures f = ReportFigures.build(
        range: _range(ReportPeriod.monthly, 2026, 5),
        currency: _cur,
        transactions: const <Transaction>[],
        budgets: const <BudgetTarget>[],
      );
      expect(f.summary.count, 0);
      expect(f.income, isEmpty);
      expect(f.expenses, isEmpty);
      expect(f.year.length, 12);
      expect(f.hasComparison, isFalse);
      expect(f.budget.hasBudget, isFalse);
    });

    test('amounts in another currency are left out of every total', () {
      final ReportFigures f = ReportFigures.build(
        range: _range(ReportPeriod.monthly, 2026, 1),
        currency: _cur,
        transactions: <Transaction>[
          _t(
              year: 2026,
              month: 1,
              major: 500,
              type: TransactionType.expense,
              currency: 'EUR'),
          _t(year: 2026, month: 1, major: 1000, type: TransactionType.expense),
        ],
        budgets: const <BudgetTarget>[],
      );
      expect(f.summary.expense, _m(1000));
    });
  });
}
