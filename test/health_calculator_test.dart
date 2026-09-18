import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';

double _scoreOf(HealthResult r, HealthIndicatorKey k) =>
    r.indicators.firstWhere((HealthIndicator i) => i.key == k).score;

void main() {
  test('weights sum to 1.00', () {
    final double sum = HealthWeights.values.values
        .fold<double>(0, (double s, double w) => s + w);
    expect(sum, closeTo(1.0, 1e-9));
  });

  test('all-zero inputs yield score 0 and needsWork', () {
    final HealthResult r = HealthCalculator.compute(
      HealthInput(
        incomeMinor: 0,
        expenseMinor: 0,
        owedByMeMinor: 0,
        plannedExpenseMinor: 0,
        goalsProgress: 0,
        monthlyIncomesMinor: List<int>.filled(12, 0),
      ),
    );
    expect(r.score, 0);
    expect(r.status, HealthStatus.needsWork);
  });

  test('reference scenario matches the V1 weighted model', () {
    final HealthResult r = HealthCalculator.compute(
      HealthInput(
        incomeMinor: 1000,
        expenseMinor: 800,
        owedByMeMinor: 0,
        plannedExpenseMinor: 900,
        goalsProgress: 0.5,
        monthlyIncomesMinor: List<int>.filled(12, 100), // stable → 100
      ),
    );

    // Per-indicator normalized scores (0..100).
    expect(_scoreOf(r, HealthIndicatorKey.cashFlow), closeTo(100, 1e-6));
    expect(_scoreOf(r, HealthIndicatorKey.savings), closeTo(100, 1e-6));
    expect(_scoreOf(r, HealthIndicatorKey.expense), closeTo(40, 1e-6));
    expect(_scoreOf(r, HealthIndicatorKey.debt), closeTo(100, 1e-6));
    expect(_scoreOf(r, HealthIndicatorKey.goals), closeTo(50, 1e-6));
    expect(_scoreOf(r, HealthIndicatorKey.budget), closeTo(100, 1e-6)); // clamped
    expect(_scoreOf(r, HealthIndicatorKey.incomeStability), closeTo(100, 1e-6));

    // Composite = 20+20+6+15+5+10+10 = 86.
    expect(r.score, closeTo(86, 1e-6));
    expect(r.status, HealthStatus.veryGood);
  });
}
