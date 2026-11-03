/// Everything a report prints, worked out once and without the assistant.
///
/// The document, the charts and the brief the assistant is given all read
/// from this one object, so a figure cannot differ between the table, the
/// bar beside it and the sentence about it.
///
/// Pure: raw lists in, figures out. No providers, no Flutter, no network —
/// see test/report_figures_test.dart.
library;

import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/reports/domain/report_range.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// How a figure moved against the period before it.
@immutable
class PeriodChange {
  const PeriodChange({required this.now, required this.before});

  final Money now;
  final Money before;

  Money get delta =>
      Money(now.minorUnits - before.minorUnits, now.currencyCode);

  /// The move as a share of the earlier figure, or null when there is nothing
  /// to divide by. A report that printed "+100%" against a zero month would
  /// be stating a fact it does not have.
  double? get ratio {
    if (before.minorUnits == 0) return null;
    return (now.minorUnits - before.minorUnits) / before.minorUnits.abs();
  }

  bool get isUp => delta.minorUnits > 0;
  bool get isFlat => delta.minorUnits == 0;
}

/// The plan against the spending, over the report's own months.
@immutable
class BudgetFigures {
  const BudgetFigures({
    required this.planned,
    required this.spent,
    required this.categories,
  });

  /// Everything planned in the range's months, in the base currency.
  final Money planned;

  /// Spent in the range **in the budgeted categories only**, so the two sides
  /// measure the same thing. Spending in a category with no budget is in the
  /// expense table, not here.
  final Money spent;

  /// How many categories carry a plan in this range.
  final int categories;

  bool get hasBudget => planned.minorUnits > 0;

  Money get remaining =>
      Money(planned.minorUnits - spent.minorUnits, planned.currencyCode);

  /// Spent over planned; null when nothing is planned.
  double? get used {
    if (planned.minorUnits <= 0) return null;
    return spent.minorUnits / planned.minorUnits;
  }

  bool get isOver =>
      planned.minorUnits > 0 && spent.minorUnits > planned.minorUnits;

  static BudgetFigures none(String currency) => BudgetFigures(
        planned: Money(0, currency),
        spent: Money(0, currency),
        categories: 0,
      );
}

/// The whole report, as numbers.
@immutable
class ReportFigures {
  const ReportFigures({
    required this.range,
    required this.currency,
    required this.summary,
    required this.income,
    required this.expenses,
    required this.budget,
    required this.year,
    this.previous,
    this.debts,
    this.healthScore,
  });

  final ReportRange range;
  final String currency;

  final FinanceSummary summary;
  final List<CategoryTotal> income;
  final List<CategoryTotal> expenses;
  final BudgetFigures budget;

  /// The twelve months of [ReportRange.year], for the trend chart. Always the
  /// whole year, whatever the period, so a monthly report still shows where
  /// its month sits.
  final List<MonthPoint> year;

  /// The period before this one, or null when it holds nothing at all —
  /// a first month has no comparison to make.
  final FinanceSummary? previous;

  /// Debts as they stand today. Not period figures: a debt is a standing
  /// balance, and the report says so.
  final DebtSummary? debts;

  /// 0..100, or null when there is too little data to score.
  final double? healthScore;

  bool get hasComparison => previous != null;

  PeriodChange? get incomeChange => previous == null
      ? null
      : PeriodChange(now: summary.income, before: previous!.income);

  PeriodChange? get expenseChange => previous == null
      ? null
      : PeriodChange(now: summary.expense, before: previous!.expense);

  PeriodChange? get netChange => previous == null
      ? null
      : PeriodChange(now: summary.net, before: previous!.net);

  /// Savings-rate points gained or lost, or null without a comparison.
  double? get savingsRateChange =>
      previous == null ? null : summary.savingsRate - previous!.savingsRate;

  /// Builds the figures from the raw records.
  ///
  /// [transactions] is every transaction the account has: the range before
  /// this one may sit in the year before, so filtering to one year first
  /// would quietly drop January's comparison.
  static ReportFigures build({
    required ReportRange range,
    required String currency,
    required List<Transaction> transactions,
    required List<BudgetTarget> budgets,
    DebtSummary? debts,
    double? healthScore,
  }) {
    final List<Transaction> inRange = transactions
        .where((Transaction t) => range.contains(t.date))
        .toList(growable: false);

    final ReportRange before = range.previous;
    final List<Transaction> inBefore = transactions
        .where((Transaction t) => before.contains(t.date))
        .toList(growable: false);

    return ReportFigures(
      range: range,
      currency: currency,
      summary: FinanceCalculator.summarize(inRange, currency),
      income: FinanceCalculator.categoryTotals(
          inRange, TransactionType.income, currency),
      expenses: FinanceCalculator.categoryTotals(
          inRange, TransactionType.expense, currency),
      budget: _budget(range, currency, inRange, budgets),
      year: FinanceCalculator.monthlyTotals(transactions, range.year, currency),
      previous: inBefore.isEmpty
          ? null
          : FinanceCalculator.summarize(inBefore, currency),
      debts: debts,
      healthScore: healthScore,
    );
  }

  static BudgetFigures _budget(
    ReportRange range,
    String currency,
    List<Transaction> inRange,
    List<BudgetTarget> budgets,
  ) {
    final Set<int> months =
        range.months.map((({int month, int year}) m) => m.month).toSet();

    int planned = 0;
    final Set<String> budgeted = <String>{};
    for (final BudgetTarget b in budgets) {
      if (b.year != range.year) continue;
      if (!months.contains(b.month)) continue;
      if (b.planned.currencyCode != currency) continue;
      planned += b.planned.minorUnits;
      budgeted.add(b.category);
    }
    if (planned == 0) return BudgetFigures.none(currency);

    int spent = 0;
    for (final Transaction t in inRange) {
      if (t.isIncome) continue;
      if (t.amount.currencyCode != currency) continue;
      if (!budgeted.contains(t.category)) continue;
      spent += t.amount.minorUnits;
    }

    return BudgetFigures(
      planned: Money(planned, currency),
      spent: Money(spent, currency),
      categories: budgeted.length,
    );
  }
}
