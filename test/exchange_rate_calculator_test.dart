import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/exchange_rates/domain/exchange_rate_calculator.dart';

void main() {
  const Map<String, double> rates = <String, double>{
    'USD': 1.0,
    'SAR': 3.75,
    'EUR': 0.92,
  };

  double convert(double amount, String from, String to) =>
      ExchangeRateCalculator.convert(
          amount: amount, from: from, to: to, ratesVsUsd: rates);

  test('same currency returns the amount unchanged', () {
    expect(convert(100, 'SAR', 'SAR'), 100);
  });

  test('USD -> SAR uses the rate directly', () {
    expect(convert(100, 'USD', 'SAR'), closeTo(375, 1e-9));
  });

  test('SAR -> USD is the inverse', () {
    expect(convert(375, 'SAR', 'USD'), closeTo(100, 1e-9));
  });

  test('cross rate goes through USD', () {
    // 100 SAR -> USD (100/3.75) -> EUR (*0.92)
    expect(convert(100, 'SAR', 'EUR'), closeTo(100 / 3.75 * 0.92, 1e-9));
  });

  test('missing or zero rate yields 0 (never a wrong number)', () {
    expect(convert(100, 'USD', 'JPY'), 0);
  });
}
