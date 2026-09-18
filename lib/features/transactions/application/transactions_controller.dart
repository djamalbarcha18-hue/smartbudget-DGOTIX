import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/transactions/data/fake_transaction_repository.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/domain/transaction_repository.dart';

/// Binds the active [TransactionRepository], scoped to the signed-in user so
/// data is isolated per account. P3 uses the local dev store; swap to Supabase
/// here in a later phase.
final financeRepositoryProvider = Provider<TransactionRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final TransactionRepository repo = FakeTransactionRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live list of the user's transactions (newest first).
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(financeRepositoryProvider).watchAll();
});

/// Currently viewed year (defaults to the current calendar year).
final selectedYearProvider =
    StateProvider<int>((ref) => DateTime.now().year);

/// Currently viewed month 1..12 (for the Monthly Budget screen).
final selectedMonthProvider =
    StateProvider<int>((ref) => DateTime.now().month);

/// Transactions filtered to the selected year AND month.
final monthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final List<Transaction> all =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final int year = ref.watch(selectedYearProvider);
  final int month = ref.watch(selectedMonthProvider);
  return FinanceCalculator.forMonth(all, year, month);
});

/// Summary for the selected month in the base currency.
final monthlySummaryProvider = Provider<FinanceSummary>((ref) {
  final List<Transaction> txns = ref.watch(monthTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.summarize(txns, currency);
});

/// Expense category totals for the selected month.
final monthExpenseCategoryTotalsProvider =
    Provider<List<CategoryTotal>>((ref) {
  final List<Transaction> txns = ref.watch(monthTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.categoryTotals(
      txns, TransactionType.expense, currency);
});

/// Transactions filtered to the selected year.
final yearTransactionsProvider = Provider<List<Transaction>>((ref) {
  final List<Transaction> all =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final int year = ref.watch(selectedYearProvider);
  return FinanceCalculator.forYear(all, year);
});

/// Aggregated KPI summary for the selected year in the base currency.
final financeSummaryProvider = Provider<FinanceSummary>((ref) {
  final List<Transaction> txns = ref.watch(yearTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.summarize(txns, currency);
});

/// Expense totals per category (descending) for the selected year.
final expenseCategoryTotalsProvider = Provider<List<CategoryTotal>>((ref) {
  final List<Transaction> txns = ref.watch(yearTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.categoryTotals(
      txns, TransactionType.expense, currency);
});

/// Income totals per category (descending) for the selected year.
final incomeCategoryTotalsProvider = Provider<List<CategoryTotal>>((ref) {
  final List<Transaction> txns = ref.watch(yearTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.categoryTotals(
      txns, TransactionType.income, currency);
});

/// Summary for the PREVIOUS year (selected year − 1), for KPI comparisons.
final previousYearSummaryProvider = Provider<FinanceSummary>((ref) {
  final List<Transaction> all =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final int prevYear = ref.watch(selectedYearProvider) - 1;
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.summarize(
      FinanceCalculator.forYear(all, prevYear), currency);
});

/// 12-month income/expense/net series for the selected year (base currency).
final monthlyTrendProvider = Provider<List<MonthPoint>>((ref) {
  final List<Transaction> txns = ref.watch(yearTransactionsProvider);
  final int year = ref.watch(selectedYearProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return FinanceCalculator.monthlyTotals(txns, year, currency);
});

/// Actions facade the UI calls to mutate transactions.
final transactionActionsProvider = Provider<TransactionActions>((ref) {
  return TransactionActions(ref.watch(financeRepositoryProvider));
});

class TransactionActions {
  TransactionActions(this._repo);
  final TransactionRepository _repo;

  Future<void> add(Transaction txn) => _repo.add(txn);
  Future<void> update(Transaction txn) => _repo.update(txn);
  Future<void> delete(String id) => _repo.delete(id);

  static String newId() =>
      'txn-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
