import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';

InsightInput _input({
  int transactionCount = 5,
  int netMinor = 0,
  double savingsRate = 0,
  bool hasHealth = false,
  HealthStatus? healthStatus,
  int overdueDebts = 0,
  int urgentGoals = 0,
  int achievedGoals = 0,
  int owedToMeMinor = 0,
  int owedByMeMinor = 0,
  bool zakatDue = false,
}) {
  return InsightInput(
    currency: 'USD',
    transactionCount: transactionCount,
    netMinor: netMinor,
    savingsRate: savingsRate,
    hasHealth: hasHealth,
    healthStatus: healthStatus,
    overdueDebts: overdueDebts,
    urgentGoals: urgentGoals,
    achievedGoals: achievedGoals,
    owedToMeMinor: owedToMeMinor,
    owedByMeMinor: owedByMeMinor,
    zakatDue: zakatDue,
  );
}

List<InsightKey> _keys(List<Insight> l) =>
    l.map((Insight i) => i.key).toList();

void main() {
  test('no transactions yields no insights', () {
    expect(InsightEngine.generate(_input(transactionCount: 0)), isEmpty);
  });

  test('always reports the savings rate as a neutral fact', () {
    final List<Insight> out = InsightEngine.generate(_input());
    final Insight rate =
        out.firstWhere((Insight i) => i.key == InsightKey.savingsRate);
    expect(rate.tone, InsightTone.info);
  });

  test('negative net produces a deficit warning; positive a surplus positive',
      () {
    final List<Insight> deficit =
        InsightEngine.generate(_input(netMinor: -5000));
    final Insight d =
        deficit.firstWhere((Insight i) => i.key == InsightKey.netDeficit);
    expect(d.tone, InsightTone.warning);
    expect(d.amountMinor, 5000); // magnitude, positive

    final List<Insight> surplus =
        InsightEngine.generate(_input(netMinor: 5000));
    expect(_keys(surplus), contains(InsightKey.netSurplus));
    expect(_keys(surplus), isNot(contains(InsightKey.netDeficit)));
  });

  test('warnings are ordered before positives', () {
    final List<Insight> out = InsightEngine.generate(_input(
      netMinor: 5000, // positive (surplus)
      overdueDebts: 2, // warning
      achievedGoals: 1, // positive
    ));
    final int firstWarning =
        out.indexWhere((Insight i) => i.tone == InsightTone.warning);
    final int firstPositive =
        out.indexWhere((Insight i) => i.tone == InsightTone.positive);
    expect(firstWarning, greaterThanOrEqualTo(0));
    expect(firstWarning, lessThan(firstPositive));
  });

  test('health band maps to the matching insight + tone', () {
    final List<Insight> out = InsightEngine.generate(
        _input(hasHealth: true, healthStatus: HealthStatus.needsWork));
    final Insight h = out.firstWhere(
        (Insight i) => i.key == InsightKey.healthNeedsWork);
    expect(h.tone, InsightTone.warning);
  });

  test('health is omitted when there is no health data', () {
    final List<Insight> out = InsightEngine.generate(
        _input(hasHealth: false, healthStatus: HealthStatus.good));
    expect(
      out.where((Insight i) => i.key.name.startsWith('health')),
      isEmpty,
    );
  });

  test('zakat insight only appears when obligatory', () {
    expect(_keys(InsightEngine.generate(_input(zakatDue: false))),
        isNot(contains(InsightKey.zakatDue)));
    expect(_keys(InsightEngine.generate(_input(zakatDue: true))),
        contains(InsightKey.zakatDue));
  });
}
