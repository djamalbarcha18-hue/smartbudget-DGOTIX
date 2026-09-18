import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

const String usd = 'USD';

ZakatInput _input({
  double gold = 100,
  double silver = 1,
  ZakatStandard standard = ZakatStandard.gold,
  double savings = 0,
  double surplus = 0,
  double receivables = 0,
  double liabilities = 0,
}) {
  int m(double v) => Money.fromDouble(v, usd).minorUnits;
  return ZakatInput(
    currency: usd,
    standard: standard,
    goldPricePerGram: gold,
    silverPricePerGram: silver,
    savingsMinor: m(savings),
    surplusMinor: m(surplus),
    receivablesMinor: m(receivables),
    liabilitiesMinor: m(liabilities),
  );
}

void main() {
  test('gold nisab = 85 * gold price; adopted per standard', () {
    final ZakatResult r = ZakatCalculator.compute(_input(gold: 100));
    expect(r.goldNisab, Money.fromDouble(8500, usd)); // 85 * 100
    expect(r.adoptedNisab, r.goldNisab);
  });

  test('obligatory above nisab; due = 2.5% of net zakatable', () {
    final ZakatResult r = ZakatCalculator.compute(_input(gold: 100, savings: 10000));
    // net 10000 >= nisab 8500 -> due 250
    expect(r.netZakatable, Money.fromDouble(10000, usd));
    expect(r.obligatory, isTrue);
    expect(r.due, Money.fromDouble(250, usd));
  });

  test('below nisab -> not obligatory, due 0', () {
    final ZakatResult r = ZakatCalculator.compute(_input(gold: 100, savings: 5000));
    expect(r.obligatory, isFalse);
    expect(r.due.isZero, isTrue);
  });

  test('liabilities reduce the zakatable base; negative clamps to 0', () {
    final ZakatResult r = ZakatCalculator.compute(
        _input(gold: 100, savings: 2000, liabilities: 5000));
    expect(r.netZakatable.isZero, isTrue);
    expect(r.obligatory, isFalse);
  });

  test('silver standard uses the lower 595g nisab', () {
    final ZakatResult r = ZakatCalculator.compute(
        _input(standard: ZakatStandard.silver, silver: 1, savings: 1000));
    expect(r.adoptedNisab, Money.fromDouble(595, usd)); // 595 * 1
    expect(r.obligatory, isTrue); // 1000 >= 595
  });
}
