import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The time scope the dashboard KPIs / donuts reflect. Multi-month context
/// (12-month comparison, markets, health) stays independent of this.
enum DashboardScope { month, year }

/// Current dashboard period scope (defaults to the current month — closest to
/// day-to-day budgeting). Switchable at any time; per-viewer, not persisted.
final dashboardScopeProvider =
    StateProvider<DashboardScope>((ref) => DashboardScope.month);

/// Transactions for the active scope (selected month, or the whole year).
final scopedTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(dashboardScopeProvider) == DashboardScope.month
      ? ref.watch(monthTransactionsProvider)
      : ref.watch(yearTransactionsProvider);
});

/// KPI summary for the active scope.
final scopedSummaryProvider = Provider<FinanceSummary>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.summarize(
      ref.watch(scopedTransactionsProvider), currency);
});

/// Previous-period summary for the KPI deltas (previous month, or previous
/// year), handling the December→January rollover.
final scopedPreviousSummaryProvider = Provider<FinanceSummary>((ref) {
  final DashboardScope scope = ref.watch(dashboardScopeProvider);
  if (scope == DashboardScope.year) {
    return ref.watch(previousYearSummaryProvider);
  }
  final String currency = ref.watch(baseCurrencyProvider);
  final List<Transaction> all =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  int year = ref.watch(selectedYearProvider);
  int month = ref.watch(selectedMonthProvider) - 1;
  if (month < 1) {
    month = 12;
    year -= 1;
  }
  return FinanceCalculator.summarize(
      FinanceCalculator.forMonth(all, year, month), currency);
});

/// Expense category totals for the active scope.
final scopedExpenseCategoryTotalsProvider =
    Provider<List<CategoryTotal>>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.categoryTotals(
      ref.watch(scopedTransactionsProvider), TransactionType.expense, currency);
});

/// Income category totals for the active scope.
final scopedIncomeCategoryTotalsProvider =
    Provider<List<CategoryTotal>>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.categoryTotals(
      ref.watch(scopedTransactionsProvider), TransactionType.income, currency);
});
