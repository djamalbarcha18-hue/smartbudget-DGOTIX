import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The seven health indicators (keys) — mirrors SmartBudget V1.
enum HealthIndicatorKey {
  cashFlow,
  savings,
  expense,
  debt,
  goals,
  budget,
  incomeStability,
}

/// Overall status bands (V1 thresholds on the 0..100 composite).
enum HealthStatus { excellent, veryGood, good, fair, needsWork }

/// Central weights — a single source of truth (sum = 1.00), identical to V1.
abstract final class HealthWeights {
  static const Map<HealthIndicatorKey, double> values =
      <HealthIndicatorKey, double>{
    HealthIndicatorKey.cashFlow: 0.20,
    HealthIndicatorKey.savings: 0.20,
    HealthIndicatorKey.expense: 0.15,
    HealthIndicatorKey.debt: 0.15,
    HealthIndicatorKey.goals: 0.10,
    HealthIndicatorKey.budget: 0.10,
    HealthIndicatorKey.incomeStability: 0.10,
  };
}

/// One indicator's computed score (0..100), weight, and weighted contribution.
@immutable
class HealthIndicator {
  const HealthIndicator({
    required this.key,
    required this.score,
    required this.weight,
  });

  final HealthIndicatorKey key;
  final double score; // 0..100
  final double weight;

  double get contribution => score * weight;
}

/// The full result: composite 0..100, status band, and the seven indicators.
@immutable
class HealthResult {
  const HealthResult({required this.score, required this.status, required this.indicators});
  final double score;
  final HealthStatus status;
  final List<HealthIndicator> indicators;
}

/// Raw inputs, all in the same base currency (minor units), for one year.
@immutable
class HealthInput {
  const HealthInput({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.owedByMeMinor,
    required this.plannedExpenseMinor,
    required this.goalsProgress,
    required this.monthlyIncomesMinor,
  });

  final int incomeMinor;
  final int expenseMinor;
  final int owedByMeMinor;
  final int plannedExpenseMinor;
  final double goalsProgress; // 0..1 (overall saved / target)
  final List<int> monthlyIncomesMinor; // length 12
}

/// Pure financial-health engine — a faithful re-implementation of the V1
/// weighted-score model (see FinancialHealth.gs). Every indicator is normalized
/// to 0..100, then the composite is the weight-sum. Guarded against /0.
abstract final class HealthCalculator {
  static double _clamp(double v) => v.clamp(0, 100).toDouble();

  static HealthResult compute(HealthInput i) {
    final double income = i.incomeMinor.toDouble();
    final double expense = i.expenseMinor.toDouble();
    final double net = income - expense;

    // (1) Cash flow: (net/income) vs a 20% target.
    final double cashFlow =
        income == 0 ? 0 : _clamp((net / income) / 0.2 * 100);

    // (2) Savings rate vs a 20% target.
    final double savingsRate = income == 0 ? 0 : net / income;
    final double savings = income == 0 ? 0 : _clamp(savingsRate / 0.2 * 100);

    // (3) Expense efficiency: lower expense/income is better (0.5 reference).
    final double expenseScore =
        income == 0 ? 0 : _clamp((1 - expense / income) / 0.5 * 100);

    // (4) Debt sustainability: liabilities/income against a 0.4 ceiling.
    final double debt = income == 0
        ? 0
        : _clamp((1 - (i.owedByMeMinor / income) / 0.4) * 100);

    // (5) Goals progress (overall saved/target).
    final double goals = _clamp(i.goalsProgress * 100);

    // (6) Budget discipline: planned/actual (needs planned budget targets).
    final double budget =
        expense == 0 ? 0 : _clamp(i.plannedExpenseMinor / expense * 100);

    // (7) Income stability: 1 - coefficient of variation across the 12 months.
    final double stability = _incomeStability(i.monthlyIncomesMinor);

    final Map<HealthIndicatorKey, double> scores = <HealthIndicatorKey, double>{
      HealthIndicatorKey.cashFlow: cashFlow,
      HealthIndicatorKey.savings: savings,
      HealthIndicatorKey.expense: expenseScore,
      HealthIndicatorKey.debt: debt,
      HealthIndicatorKey.goals: goals,
      HealthIndicatorKey.budget: budget,
      HealthIndicatorKey.incomeStability: stability,
    };

    final List<HealthIndicator> indicators = HealthIndicatorKey.values
        .map((HealthIndicatorKey k) => HealthIndicator(
              key: k,
              score: scores[k]!,
              weight: HealthWeights.values[k]!,
            ))
        .toList();

    final double composite = indicators.fold<double>(
        0, (double sum, HealthIndicator ind) => sum + ind.contribution);

    return HealthResult(
      score: composite,
      status: _statusOf(composite),
      indicators: indicators,
    );
  }

  static double _incomeStability(List<int> monthly) {
    if (monthly.isEmpty) return 0;
    final double avg =
        monthly.fold<int>(0, (int s, int v) => s + v) / monthly.length;
    if (avg == 0) return 0;
    final double variance = monthly.fold<double>(
          0,
          (double s, int v) => s + math.pow(v - avg, 2).toDouble(),
        ) /
        monthly.length;
    final double cv = math.sqrt(variance) / avg;
    return _clamp((1 - cv) * 100);
  }

  static HealthStatus _statusOf(double score) {
    if (score >= 90) return HealthStatus.excellent;
    if (score >= 75) return HealthStatus.veryGood;
    if (score >= 60) return HealthStatus.good;
    if (score >= 40) return HealthStatus.fair;
    return HealthStatus.needsWork;
  }
}
