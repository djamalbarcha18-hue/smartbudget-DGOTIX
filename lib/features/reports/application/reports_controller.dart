import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Aggregated report for the selected period.
@immutable
class ReportResult {
  const ReportResult({
    required this.summary,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  final FinanceSummary summary;
  final List<CategoryTotal> incomeCategories;
  final List<CategoryTotal> expenseCategories;
}

final selectedReportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.yearly);

final selectedReportSubProvider = StateProvider<int>(
    (ref) => ReportPeriods.defaultSub(ReportPeriod.yearly, DateTime.now()));

/// Transactions for the selected year filtered to the selected period's months.
final reportTransactionsProvider = Provider<List<Transaction>>((ref) {
  final List<Transaction> yearTxns = ref.watch(yearTransactionsProvider);
  final ReportPeriod period = ref.watch(selectedReportPeriodProvider);
  final int sub = ref.watch(selectedReportSubProvider);
  final Set<int> months = ReportPeriods.monthsIn(period, sub).toSet();
  return yearTxns
      .where((Transaction t) => months.contains(t.date.month))
      .toList();
});

final reportResultProvider = Provider<ReportResult>((ref) {
  final List<Transaction> txns = ref.watch(reportTransactionsProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return ReportResult(
    summary: FinanceCalculator.summarize(txns, currency),
    incomeCategories: FinanceCalculator.categoryTotals(
        txns, TransactionType.income, currency),
    expenseCategories: FinanceCalculator.categoryTotals(
        txns, TransactionType.expense, currency),
  );
});
