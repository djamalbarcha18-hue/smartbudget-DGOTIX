import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/salary_split/domain/salary_split.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String usd = 'USD';
Money m(num amount) => Money.fromDouble(amount.toDouble(), usd);

int _id = 0;
Transaction tx(String category, num amount, int year, int month,
    {TransactionType type = TransactionType.expense, String currency = usd}) {
  _id++;
  return Transaction(
    id: 't$_id',
    date: DateTime(year, month, 10),
    type: type,
    category: category,
    amount: Money.fromDouble(amount.toDouble(), currency),
    createdAt: DateTime(year, month, 10),
  );
}

/// The same spending in each of the three months before October 2026.
List<Transaction> history(Map<String, num> perMonth) => <Transaction>[
      for (final int month in <int>[7, 8, 9])
        for (final MapEntry<String, num> e in perMonth.entries)
          tx(e.key, e.value, 2026, month),
    ];

int sumSuggested(SalarySplit s) =>
    s.lines.fold(0, (int a, SplitLine l) => a + l.suggested.minorUnits);

Money suggestedFor(SalarySplit s, String category) =>
    s.lines.firstWhere((SplitLine l) => l.category == category).suggested;

SalarySplit split(Money income, List<Transaction> txns,
        {List<Goal> goals = const <Goal>[]}) =>
    SalarySplitEngine.compute(
      income: income,
      transactions: txns,
      goals: goals,
      year: 2026,
      month: 10,
      now: DateTime(2026, 10, 1),
    );

void main() {
  test('history window is the three full months before, across a new year',
      () {
    expect(SalarySplitEngine.historyWindow(2026, 2),
        <(int, int)>[(2026, 1), (2025, 12), (2025, 11)]);
  });

  test('comfortable month: needs and wants keep their averages, surplus saved',
      () {
    final SalarySplit s = split(
        m(3000), history(<String, num>{'السكن': 1000, 'الطعام': 500, 'المطاعم': 200}));
    expect(s.basis, SplitBasis.history);
    expect(s.monthsOfHistory, 3);
    expect(suggestedFor(s, 'السكن'), m(1000));
    expect(suggestedFor(s, 'الطعام'), m(500));
    expect(suggestedFor(s, 'المطاعم'), m(200));
    expect(s.savings, m(1300)); // 3000 − 1500 − 200
    expect(s.trimmed, m(0));
    expect(sumSuggested(s), m(3000).minorUnits);
  });

  test('tight month: wants are scaled down, needs untouched, 10% saved', () {
    // Needs 1500, wants 800, income 2000 → save 200, 300 left for wants.
    final SalarySplit s = split(
        m(2000),
        history(<String, num>{
          'السكن': 1000,
          'الطعام': 500,
          'المطاعم': 600,
          'التسوق': 200,
        }));
    expect(suggestedFor(s, 'السكن'), m(1000));
    expect(suggestedFor(s, 'الطعام'), m(500));
    expect(suggestedFor(s, 'المطاعم'), m(225)); // 600 × 300/800
    expect(suggestedFor(s, 'التسوق'), m(75)); // 200 × 300/800
    expect(s.savings, m(200));
    expect(s.trimmed, m(500));
    expect(sumSuggested(s), m(2000).minorUnits);
  });

  test('needs above income: no invented cuts, the gap is reported', () {
    final SalarySplit s = split(
        m(1000), history(<String, num>{'السكن': 900, 'الفواتير': 300, 'الترفيه': 100}));
    expect(s.isDeficit, isTrue);
    expect(s.shortfall, m(200));
    expect(s.wants, m(0));
    expect(s.savings, m(0));
    expect(s.lines.every((SplitLine l) => l.bucket == SplitBucket.needs),
        isTrue);
  });

  test('dated goals raise the savings target above 10%', () {
    final Goal car = Goal(
      id: 'g1',
      name: 'Car',
      target: m(6000),
      saved: m(0),
      deadline: DateTime(2027, 10, 1), // 12 months away → 500/month
      createdAt: DateTime(2026, 1, 1),
    );
    final SalarySplit s = split(
        m(2000), history(<String, num>{'السكن': 1000, 'المطاعم': 800}),
        goals: <Goal>[car]);
    expect(s.goalsMonthly, m(500));
    expect(s.savings, m(500));
    expect(suggestedFor(s, 'المطاعم'), m(500)); // trimmed to fit
    expect(s.goalsUncovered, m(0));
    expect(sumSuggested(s), m(2000).minorUnits);
  });

  test('goals without a deadline do not swallow the salary', () {
    final Goal someday = Goal(
      id: 'g2',
      name: 'Someday',
      target: m(50000),
      saved: m(0),
      createdAt: DateTime(2026, 1, 1),
    );
    final SalarySplit s = split(
        m(2000), history(<String, num>{'السكن': 1000}),
        goals: <Goal>[someday]);
    expect(s.goalsMonthly, m(0));
    expect(s.savings, m(1000));
  });

  test('no history: 50/30/20 rule, only savings maps to a category', () {
    final SalarySplit s = split(m(1000), const <Transaction>[]);
    expect(s.basis, SplitBasis.rule);
    expect(s.needs, m(500));
    expect(s.wants, m(300));
    expect(s.savings, m(200));
    expect(s.lines.single.category, SplitClassifier.savingsCategory);
  });

  test('other currencies and months outside the window are ignored', () {
    final SalarySplit s = split(m(1000), <Transaction>[
      tx('السكن', 300, 2026, 9),
      tx('السكن', 999, 2026, 9, currency: 'EUR'),
      tx('السكن', 999, 2026, 5), // outside the 3-month window
      tx('السكن', 999, 2026, 10), // the target month itself
    ]);
    expect(s.monthsOfHistory, 1);
    expect(suggestedFor(s, 'السكن'), m(300));
  });

  test('custom categories count as wants; savings history is respected', () {
    final SalarySplit s = split(
        m(2000),
        history(<String, num>{
          'السكن': 1000,
          'هواية خاصة': 100,
          SplitClassifier.savingsCategory: 400,
        }));
    expect(
        s.lines.firstWhere((SplitLine l) => l.category == 'هواية خاصة').bucket,
        SplitBucket.wants);
    // Already saving 400/month (> 10% of 2000): keep at least that.
    expect(s.savings.minorUnits >= m(400).minorUnits, isTrue);
    expect(sumSuggested(s), m(2000).minorUnits);
  });

  test('zero income gives an empty plan instead of a guess', () {
    final SalarySplit s =
        split(m(0), history(<String, num>{'السكن': 1000}));
    expect(s.hasIncome, isFalse);
    expect(s.lines, isEmpty);
  });

  test('default income: this month if recorded, else the window average', () {
    final List<Transaction> incomes = <Transaction>[
      tx('راتب أساسي', 1800, 2026, 8, type: TransactionType.income),
      tx('راتب أساسي', 2200, 2026, 9, type: TransactionType.income),
    ];
    expect(
        SalarySplitEngine.defaultIncome(
            transactions: incomes, year: 2026, month: 10, currency: usd),
        m(2000));
    expect(
        SalarySplitEngine.defaultIncome(transactions: <Transaction>[
          ...incomes,
          tx('راتب أساسي', 2500, 2026, 10, type: TransactionType.income),
        ], year: 2026, month: 10, currency: usd),
        m(2500));
  });
}
