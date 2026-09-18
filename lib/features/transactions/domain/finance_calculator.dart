import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Aggregated totals for a set of transactions (one currency).
@immutable
class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.savingsRate,
    required this.count,
  });

  final Money income;
  final Money expense;
  final Money net;

  /// (income - expense) / income, clamped to [0..1]-ish; 0 when income is 0.
  /// Mirrors SmartBudget V1: savingsRate = (totalIncome - totalExpense)/income.
  final double savingsRate;

  final int count;
}

/// A category's total (for distribution lists / charts), sorted by callers.
@immutable
class CategoryTotal {
  const CategoryTotal({required this.category, required this.amount});
  final String category;
  final Money amount;
}

/// One calendar month's totals (for the 12-month trend).
@immutable
class MonthPoint {
  const MonthPoint({
    required this.monthIndex, // 0..11
    required this.income,
    required this.expense,
    required this.net,
  });
  final int monthIndex;
  final Money income;
  final Money expense;
  final Money net;
}

/// Pure financial calculators — a faithful re-implementation of the SmartBudget
/// V1 formulas. No I/O, no framework, fully unit-testable.
///
/// All inputs are assumed to share [baseCurrency]; transactions in any other
/// currency are ignored (cross-currency conversion is a later phase, never
/// invented here).
abstract final class FinanceCalculator {
  static Iterable<Transaction> _inCurrency(
    List<Transaction> txns,
    String baseCurrency,
  ) =>
      txns.where((Transaction t) => t.amount.currencyCode == baseCurrency);

  static FinanceSummary summarize(
    List<Transaction> txns,
    String baseCurrency,
  ) {
    var incomeMinor = 0;
    var expenseMinor = 0;
    var count = 0;
    for (final Transaction t in _inCurrency(txns, baseCurrency)) {
      count++;
      if (t.isIncome) {
        incomeMinor += t.amount.minorUnits;
      } else {
        expenseMinor += t.amount.minorUnits;
      }
    }
    final int netMinor = incomeMinor - expenseMinor;
    final double savingsRate = incomeMinor == 0 ? 0 : netMinor / incomeMinor;
    return FinanceSummary(
      income: Money(incomeMinor, baseCurrency),
      expense: Money(expenseMinor, baseCurrency),
      net: Money(netMinor, baseCurrency),
      savingsRate: savingsRate,
      count: count,
    );
  }

  /// Totals per category for a given type, descending by amount.
  static List<CategoryTotal> categoryTotals(
    List<Transaction> txns,
    TransactionType type,
    String baseCurrency,
  ) {
    final Map<String, int> byCat = <String, int>{};
    for (final Transaction t in _inCurrency(txns, baseCurrency)) {
      if (t.type != type) continue;
      byCat.update(
        t.category.isEmpty ? '—' : t.category,
        (int v) => v + t.amount.minorUnits,
        ifAbsent: () => t.amount.minorUnits,
      );
    }
    final List<CategoryTotal> out = byCat.entries
        .map((MapEntry<String, int> e) =>
            CategoryTotal(category: e.key, amount: Money(e.value, baseCurrency)))
        .toList()
      ..sort((CategoryTotal a, CategoryTotal b) =>
          b.amount.minorUnits.compareTo(a.amount.minorUnits));
    return out;
  }

  /// 12-month income/expense/net series for [year].
  static List<MonthPoint> monthlyTotals(
    List<Transaction> txns,
    int year,
    String baseCurrency,
  ) {
    final List<int> inc = List<int>.filled(12, 0);
    final List<int> exp = List<int>.filled(12, 0);
    for (final Transaction t in _inCurrency(txns, baseCurrency)) {
      if (t.date.year != year) continue;
      final int m = t.date.month - 1;
      if (t.isIncome) {
        inc[m] += t.amount.minorUnits;
      } else {
        exp[m] += t.amount.minorUnits;
      }
    }
    return List<MonthPoint>.generate(
      12,
      (int i) => MonthPoint(
        monthIndex: i,
        income: Money(inc[i], baseCurrency),
        expense: Money(exp[i], baseCurrency),
        net: Money(inc[i] - exp[i], baseCurrency),
      ),
    );
  }

  /// Transactions for [year], newest first (already sorted by the repository).
  static List<Transaction> forYear(List<Transaction> txns, int year) =>
      txns.where((Transaction t) => t.date.year == year).toList();

  /// Transactions for a specific [year]/[month] (month is 1..12).
  static List<Transaction> forMonth(
    List<Transaction> txns,
    int year,
    int month,
  ) =>
      txns
          .where((Transaction t) => t.date.year == year && t.date.month == month)
          .toList();
}
