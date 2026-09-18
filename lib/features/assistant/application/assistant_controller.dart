import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

/// Gathers already-computed figures from every feature and runs the pure
/// [InsightEngine]. All the financial reasoning lives in the existing domain
/// calculators — this provider only reads their results and hands them over.
final insightsProvider = Provider<List<Insight>>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final FinanceSummary summary = ref.watch(financeSummaryProvider);

  // Health (only meaningful once there is any income/expense).
  final bool hasHealth = ref.watch(healthHasDataProvider);
  final HealthResult health = ref.watch(healthResultProvider);

  // Largest expense category (list is already sorted descending).
  final List<CategoryTotal> expenses = ref.watch(expenseCategoryTotalsProvider);
  final CategoryTotal? topExpense = expenses.isEmpty ? null : expenses.first;

  // Goals: achieved + urgent counts, in base currency only.
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  var achievedGoals = 0;
  var urgentGoals = 0;
  for (final Goal g in goals) {
    if (GoalCalculator.status(g) == GoalStatus.completed) achievedGoals++;
    if (GoalCalculator.urgency(g) == GoalUrgency.urgent) urgentGoals++;
  }

  // Debts: overdue count (base currency, still owed) + net position.
  final List<Debt> debts =
      ref.watch(debtsProvider).valueOrNull ?? const <Debt>[];
  var overdueDebts = 0;
  for (final Debt d in debts) {
    if (d.original.currencyCode == currency &&
        DebtCalculator.status(d) == DebtStatus.overdue) {
      overdueDebts++;
    }
  }
  final DebtSummary debtSummary = ref.watch(debtSummaryProvider);

  // Zakat (obligatory only once a nisab price has been entered).
  final ZakatResult zakat = ref.watch(zakatResultProvider);

  return InsightEngine.generate(
    InsightInput(
      currency: currency,
      transactionCount: summary.count,
      netMinor: summary.net.minorUnits,
      savingsRate: summary.savingsRate,
      hasHealth: hasHealth,
      healthStatus: hasHealth ? health.status : null,
      topExpenseCategory: topExpense?.category,
      topExpenseMinor: topExpense?.amount.minorUnits ?? 0,
      achievedGoals: achievedGoals,
      urgentGoals: urgentGoals,
      overdueDebts: overdueDebts,
      owedToMeMinor: debtSummary.owedToMe.minorUnits,
      owedByMeMinor: debtSummary.owedByMe.minorUnits,
      zakatDue: zakat.obligatory,
      zakatDueMinor: zakat.due.minorUnits,
    ),
  );
});
