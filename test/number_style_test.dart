import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/money/number_style.dart';
import 'package:smartbudget/core/settings/number_style_controller.dart';

void main() {
  tearDown(() => MoneyFormatter.style = NumberStyle.commaDot);

  test('the three styles', () {
    expect(NumberStyle.commaDot.sample, '1,234,567.89');
    expect(NumberStyle.dotComma.sample, '1.234.567,89');
    expect(NumberStyle.spaceComma.sample, '1 234 567,89');
    expect(NumberStyle.fromName('dotComma'), NumberStyle.dotComma);
    expect(NumberStyle.fromName(null), NumberStyle.commaDot);
    expect(NumberStyle.fromName('nonsense'), NumberStyle.commaDot);
  });

  test('amounts, short amounts and percentages follow the style', () {
    const Money m = Money(123456789, 'USD'); // 1,234,567.89
    expect(MoneyFormatter.format(m, withSymbol: false), '1,234,567.89');
    MoneyFormatter.style = NumberStyle.dotComma;
    expect(MoneyFormatter.format(m, withSymbol: false), '1.234.567,89');
    expect(MoneyFormatter.format(m), contains('1.234.567,89'));
    expect(MoneyFormatter.compact(m), contains('1,23M'));
    expect(MoneyFormatter.percent(0.158), '15,8%');
    MoneyFormatter.style = NumberStyle.spaceComma;
    expect(MoneyFormatter.format(m, withSymbol: false), '1 234 567,89');
    // Zero-decimal currencies have no decimal part to change.
    expect(
        MoneyFormatter.format(const Money(1500000, 'JPY'), withSymbol: false),
        '1 500 000');
  });

  group('typed amounts', () {
    test('1,234.56 style', () {
      const NumberStyle s = NumberStyle.commaDot;
      expect(AmountInput.parse('12,500', style: s), 12500); // not 12.5
      expect(AmountInput.parse('1,250,000', style: s), 1250000);
      expect(AmountInput.parse('1,250,000.75', style: s), 1250000.75);
      expect(AmountInput.parse('12.5', style: s), 12.5);
      expect(AmountInput.parse('12,5', style: s), 12.5);
      expect(AmountInput.parse('1.250', style: s), 1.25); // 3-decimal dinar
      expect(AmountInput.parse('1234.567', style: s), 1234.567);
      expect(AmountInput.parse(' 2500 ', style: s), 2500);
    });

    test('1.234,56 style', () {
      const NumberStyle s = NumberStyle.dotComma;
      expect(AmountInput.parse('12.500', style: s), 12500);
      expect(AmountInput.parse('1.250.000', style: s), 1250000);
      expect(AmountInput.parse('1.250.000,75', style: s), 1250000.75);
      expect(AmountInput.parse('12,5', style: s), 12.5);
      expect(AmountInput.parse('12.5', style: s), 12.5);
      expect(AmountInput.parse('1,250', style: s), 1.25);
    });

    test('1 234,56 style', () {
      const NumberStyle s = NumberStyle.spaceComma;
      expect(AmountInput.parse('1 250 000', style: s), 1250000);
      expect(AmountInput.parse('1 250 000,5', style: s), 1250000.5);
      expect(AmountInput.parse('12,5', style: s), 12.5);
    });

    test('Arabic digits and separators, empty and junk', () {
      expect(AmountInput.parse('١٢٬٥٠٠', style: NumberStyle.commaDot), 12500);
      expect(AmountInput.parse('١٢٫٥', style: NumberStyle.commaDot), 12.5);
      expect(AmountInput.parse(''), isNull);
      expect(AmountInput.parse(null), isNull);
      expect(AmountInput.parse('abc'), isNull);
      expect(AmountInput.parse('12a'), isNull);
    });

    test('a field\'s starting text reads back as the same amount', () {
      for (final NumberStyle s in NumberStyle.values) {
        for (final double v in <double>[0, 7, 12500, 12.5, 1.125, 1234.567]) {
          final String text = AmountInput.text(v, style: s);
          expect(AmountInput.parse(text, style: s), v, reason: '$s $text');
        }
      }
      expect(AmountInput.text(12.5, style: NumberStyle.dotComma), '12,5');
      expect(AmountInput.text(12500, style: NumberStyle.dotComma), '12500');
    });
  });

  testWidgets('a new style shows on screens already open',
      (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Text(MoneyFormatter.format(
            const Money(123456789, 'USD'),
            withSymbol: false)),
      ),
    ));
    expect(find.text('1,234,567.89'), findsOneWidget);
    applyNumberStyle(NumberStyle.dotComma);
    await t.pump();
    expect(find.text('1.234.567,89'), findsOneWidget);
  });
}
