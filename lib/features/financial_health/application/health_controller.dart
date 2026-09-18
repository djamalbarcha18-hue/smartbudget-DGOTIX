import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// True once there is enough data (any income/expense) to score.
final healthHasDataProvider = Provider<bool>((ref) {
  return ref.watch(financeSummaryProvider).count > 0;
});

/// The composite financial-health result for the selected year, computed from
/// live transactions, goals, debts and budget targets via [HealthCalculator].
final healthResultProvider = Provider<HealthResult>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final int year = ref.watch(selectedYearProvider);
  final FinanceSummary summary = ref.watch(financeSummaryProvider);

  // Monthly income series for the stability indicator.
  final List<MonthPoint> months = FinanceCalculator.monthlyTotals(
    ref.watch(yearTransactionsProvider),
    year,
    currency,
  );
  final List<int> monthlyIncomes =
      months.map((MonthPoint m) => m.income.minorUnits).toList();

  // Debts (liabilities I owe).
  final DebtSummary debts = ref.watch(debtSummaryProvider);

  // Goals overall progress (saved / target across goals in the base currency).
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  var targetMinor = 0;
  var savedMinor = 0;
  for (final Goal g in goals) {
    if (g.target.currencyCode != currency) continue;
    targetMinor += g.target.minorUnits;
    savedMinor += g.saved.minorUnits;
  }
  final double goalsProgress =
      targetMinor == 0 ? 0 : savedMinor / targetMinor;

  // Planned expense for the year (budget discipline).
  final int plannedExpense = ref.watch(yearPlannedExpenseProvider).minorUnits;

  return HealthCalculator.compute(
    HealthInput(
      incomeMinor: summary.income.minorUnits,
      expenseMinor: summary.expense.minorUnits,
      owedByMeMinor: debts.owedByMe.minorUnits,
      plannedExpenseMinor: plannedExpense,
      goalsProgress: goalsProgress,
      monthlyIncomesMinor: monthlyIncomes,
    ),
  );
});
