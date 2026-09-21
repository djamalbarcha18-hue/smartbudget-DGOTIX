import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/financial_health/domain/health_engine.dart';

HealthFacts _facts({
  required int income,
  required int expense,
  int essential = 0,
  int discretionary = 0,
  int debtService = 0,
  int planned = 0,
  int owedByMe = 0,
  List<int>? mIncome,
  List<int>? mExpense,
  double goalsProgress = 0,
  int goalsCount = 0,
  int? emergency,
  bool debtCurrent = true,
}) {
  return HealthFacts(
    incomeMinor: income,
    expenseMinor: expense,
    essentialExpenseMinor: essential,
    discretionaryExpenseMinor: discretionary,
    debtServiceMinor: debtService,
    plannedExpenseMinor: planned,
    owedByMeMinor: owedByMe,
    monthlyIncome: mIncome ?? List<int>.filled(12, income ~/ 12),
    monthlyExpense: mExpense ?? List<int>.filled(12, expense ~/ 12),
    goalsProgress: goalsProgress,
    goalsCount: goalsCount,
    emergencySavingsMinor: emergency,
    debtDataCurrent: debtCurrent,
  );
}

HealthPillar _p(HealthReport r, HealthPillarKey k) =>
    r.pillars.firstWhere((HealthPillar p) => p.key == k);

bool _risk(HealthReport r, RiskKind k) =>
    r.risks.any((HealthRisk x) => x.kind == k);

void main() {
  test('weights sum to 1.00', () {
    final double s = HealthEngine.weights.values
        .fold<double>(0, (double a, double b) => a + b);
    expect(s, closeTo(1.0, 1e-9));
  });

  test('1) high income, low debt, strong liquidity → excellent, no risks', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1440000,
      expense: 1080000,
      essential: 720000,
      discretionary: 360000,
      emergency: 360000, // 6 months of 60k essentials
      goalsCount: 1,
      goalsProgress: 0.6,
    ));
    expect(r.score, greaterThanOrEqualTo(82));
    expect(r.status,
        anyOf(HealthStatus.excellent, HealthStatus.veryGood));
    expect(r.risks, isEmpty);
    expect(r.resilience, greaterThanOrEqualTo(80));
    expect(r.confidence, greaterThanOrEqualTo(80));
    expect(r.emergencyMonths, closeTo(6, 0.5));
  });

  test('2) high income but high debt → debt pillar drags the score', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1440000,
      expense: 1080000,
      essential: 700000,
      discretionary: 380000,
      debtService: 600000, // DSR ~0.417
      owedByMe: 3000000, // DTI ~2.08
      emergency: 360000,
    ));
    expect(_p(r, HealthPillarKey.debt).score, lessThan(50));
    expect(r.score, lessThan(80));
  });

  test('3) low income + strong saving → healthy (ratios, not absolutes)', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 240000,
      expense: 120000, // savings rate 50%
      essential: 90000,
      discretionary: 30000,
      emergency: 45000, // ~6 months of 7.5k essentials
    ));
    expect(r.score, greaterThanOrEqualTo(75));
    expect(_p(r, HealthPillarKey.savings).score, greaterThanOrEqualTo(90));
  });

  test('4) good cash flow but ZERO emergency fund → capped + risk', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1440000,
      expense: 1080000,
      essential: 720000,
      discretionary: 360000,
      emergency: 0, // KNOWN zero
    ));
    expect(_risk(r, RiskKind.noEmergencyBuffer), isTrue);
    expect(r.score, lessThanOrEqualTo(70));
    expect(r.emergencyMonths, closeTo(0, 0.001));
  });

  test('5) volatile income → instability risk + cap', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1200000,
      expense: 600000,
      essential: 400000,
      emergency: 300000,
      mIncome: <int>[350000, 50000, 350000, 50000, 350000, 50000, 0, 0, 0, 0, 0, 0],
      mExpense: <int>[100000, 100000, 100000, 100000, 100000, 100000, 0, 0, 0, 0, 0, 0],
    ));
    expect(_risk(r, RiskKind.incomeInstability), isTrue);
    expect(r.score, lessThanOrEqualTo(65));
  });

  test('6) persistent negative cash flow → deficit risk + hard cap', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1000000,
      expense: 1200000, // deficit every month
      essential: 800000,
    ));
    expect(_risk(r, RiskKind.negativeCashFlow), isTrue);
    expect(_risk(r, RiskKind.spendingExceedsIncome), isTrue);
    expect(r.score, lessThanOrEqualTo(50));
  });

  test('7) missing data → low confidence, no false emergency risk', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 600000,
      expense: 400000,
      essential: 250000,
      // no emergency (unknown), no goals, no budget, only 3 active months
      mIncome: <int>[200000, 200000, 200000, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      mExpense: <int>[133333, 133333, 133334, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ));
    expect(r.emergencyMonths, isNull);
    expect(_risk(r, RiskKind.noEmergencyBuffer), isFalse);
    expect(r.confidence, lessThan(80));
    expect(r.hasData, isTrue);
  });

  test('8) freelance (variable but positive) → not over-penalized', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1200000,
      expense: 800000,
      essential: 500000,
      discretionary: 200000,
      emergency: 250000,
      mIncome: <int>[120000, 90000, 110000, 100000, 130000, 90000, 110000, 100000, 90000, 120000, 40000, 100000],
      mExpense: List<int>.filled(12, 66666),
    ));
    expect(_risk(r, RiskKind.incomeInstability), isFalse);
    expect(_p(r, HealthPillarKey.incomeStability).available, isTrue);
    expect(r.score, greaterThanOrEqualTo(60));
  });

  test('9) one-off big expense month does not flip the yearly verdict', () {
    final List<int> inc = List<int>.filled(12, 100000);
    final List<int> exp = List<int>.filled(12, 60000);
    exp[5] = 460000; // one large emergency month
    // Year: income 1,200,000; expense 60k*11 + 460k = 1,120,000 → net +80,000.
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1200000,
      expense: 1120000,
      essential: 700000,
      emergency: 300000,
      mIncome: inc,
      mExpense: exp,
    ));
    // Year net stays positive overall, so no persistent-deficit risk.
    expect(_risk(r, RiskKind.negativeCashFlow), isFalse);
  });

  test('10) no debt → debt pillar is 100', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1200000,
      expense: 800000,
      essential: 500000,
      emergency: 250000,
    ));
    final HealthPillar debt = _p(r, HealthPillarKey.debt);
    expect(debt.available, isTrue);
    expect(debt.score, 100);
  });

  test('11) no goals → planning pillar unavailable, score still computed', () {
    final HealthReport r = HealthEngine.evaluate(_facts(
      income: 1200000,
      expense: 800000,
      essential: 500000,
      emergency: 250000,
    ));
    expect(_p(r, HealthPillarKey.planning).available, isFalse);
    expect(r.score, greaterThan(0));
  });

  test('12) currency-agnostic: same ratios → same score at any scale', () {
    HealthReport run(int k) => HealthEngine.evaluate(_facts(
          income: 1440 * k,
          expense: 1080 * k,
          essential: 720 * k,
          discretionary: 360 * k,
          emergency: 360 * k,
          goalsCount: 1,
          goalsProgress: 0.6,
        ));
    final HealthReport usd = run(1000); // e.g. USD minor units
    final HealthReport dzd = run(1000000); // e.g. DZD-scale
    expect(dzd.score, closeTo(usd.score, 0.5));
    expect(dzd.resilience, closeTo(usd.resilience, 0.5));
  });

  test('13) past-year debt → same score, lower debt confidence', () {
    HealthReport run(bool current) => HealthEngine.evaluate(_facts(
          income: 1200000,
          expense: 800000,
          essential: 500000,
          debtService: 300000, // DSR 0.25
          owedByMe: 2400000, // DTI 2.0
          emergency: 250000,
          debtCurrent: current,
        ));
    final HealthReport now = run(true);
    final HealthReport past = run(false);
    final HealthPillar debtNow = _p(now, HealthPillarKey.debt);
    final HealthPillar debtPast = _p(past, HealthPillarKey.debt);
    // Score is untouched — confidence is what changes for a past scope.
    expect(debtPast.score, closeTo(debtNow.score, 1e-9));
    expect(debtPast.confidence, lessThan(debtNow.confidence));
    // The lower pillar confidence pulls overall Data Confidence down too.
    expect(past.confidence, lessThan(now.confidence));
  });
}
