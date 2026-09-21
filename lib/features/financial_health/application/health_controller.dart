import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';
import 'package:smartbudget/features/financial_health/domain/health_categories.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// True once there is enough data (any income/expense) to score.
final healthHasDataProvider = Provider<bool>((ref) {
  return ref.watch(financeSummaryProvider).count > 0;
});

/// User-entered liquid savings earmarked for emergencies (base-currency amount).
/// Optional: when null the engine treats emergency coverage as UNKNOWN (which
/// lowers Data Confidence) rather than assuming it is good.
final emergencySavingsProvider =
    NotifierProvider<EmergencySavingsController, double?>(
        EmergencySavingsController.new);

class EmergencySavingsController extends Notifier<double?> {
  static const String _key = 'sb_emergency_savings';

  @override
  double? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (p.containsKey(_key)) state = p.getDouble(_key);
    } catch (_) {
      // Keep null (unknown).
    }
  }

  /// Sets the amount, or clears it (null) to return to "unknown".
  Future<void> set(double? amount) async {
    state = (amount != null && amount >= 0) ? amount : null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (state != null) {
        await p.setDouble(_key, state!);
      } else {
        await p.remove(_key);
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The full financial-health report for the selected year, computed by the
/// central [HealthEngine] from live transactions, goals, debts and budgets.
final healthReportProvider = Provider<HealthReport>((ref) {
  final bool hasData = ref.watch(healthHasDataProvider);
  if (!hasData) return HealthReport.empty;

  final String currency = ref.watch(baseCurrencyProvider);
  final int year = ref.watch(selectedYearProvider);
  final FinanceSummary summary = ref.watch(financeSummaryProvider);
  final List<Transaction> yearTxns = ref.watch(yearTransactionsProvider);

  // Monthly income/expense series (trend, volatility, active months).
  final List<MonthPoint> months =
      FinanceCalculator.monthlyTotals(yearTxns, year, currency);
  final List<int> monthlyIncome =
      months.map((MonthPoint m) => m.income.minorUnits).toList();
  final List<int> monthlyExpense =
      months.map((MonthPoint m) => m.expense.minorUnits).toList();

  // Expense breakdown by category (essential / discretionary / debt service).
  final List<CategoryTotal> expenseByCat = FinanceCalculator.categoryTotals(
      yearTxns, TransactionType.expense, currency);
  int essential = 0;
  int discretionary = 0;
  int debtService = 0;
  for (final CategoryTotal t in expenseByCat) {
    final int v = t.amount.minorUnits;
    if (t.category == HealthCategories.debtService) debtService += v;
    if (HealthCategories.isEssential(t.category)) {
      essential += v;
    } else if (HealthCategories.isDiscretionary(t.category)) {
      discretionary += v;
    }
  }

  final DebtSummary debts = ref.watch(debtSummaryProvider);

  // Goals overall progress (base currency).
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  var targetMinor = 0;
  var savedMinor = 0;
  var goalsCount = 0;
  for (final Goal g in goals) {
    if (g.target.currencyCode != currency) continue;
    goalsCount++;
    targetMinor += g.target.minorUnits;
    savedMinor += g.saved.minorUnits;
  }
  final double goalsProgress = targetMinor == 0 ? 0 : savedMinor / targetMinor;

  final int plannedExpense = ref.watch(yearPlannedExpenseProvider).minorUnits;

  // Optional emergency savings (unknown when null).
  final double? emergency = ref.watch(emergencySavingsProvider);
  final int? emergencyMinor = emergency == null
      ? null
      : Money.fromDouble(emergency, currency).minorUnits;

  return HealthEngine.evaluate(
    HealthFacts(
      incomeMinor: summary.income.minorUnits,
      expenseMinor: summary.expense.minorUnits,
      essentialExpenseMinor: essential,
      discretionaryExpenseMinor: discretionary,
      debtServiceMinor: debtService,
      plannedExpenseMinor: plannedExpense,
      owedByMeMinor: debts.owedByMe.minorUnits,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      goalsProgress: goalsProgress,
      goalsCount: goalsCount,
      emergencySavingsMinor: emergencyMinor,
      // Debt balances are a present-day snapshot; only the current calendar
      // year lets us compare them to income on the same time scope. For a
      // past year we keep the debt score but lower its Data Confidence.
      debtDataCurrent: year == DateTime.now().year,
    ),
  );
});

/// Compact result (score + status) for consumers that only need the headline
/// (dashboard hero card, AI assistant) — derived from the full report.
final healthResultProvider = Provider<HealthResult>((ref) {
  return HealthResult.fromReport(ref.watch(healthReportProvider));
});
