import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/calculator/domain/calculator_engine.dart';
import 'package:smartbudget/features/calculator/presentation/calculator_page.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Presses keys written as text: digits, '.', + - * / % = s (sign), c (AC),
/// b (backspace).
CalcState run(String keys, [CalcState start = CalcState.initial]) {
  CalcState s = start;
  for (final String k in keys.split('')) {
    final int? d = int.tryParse(k);
    s = d != null
        ? Calculator.digit(s, d)
        : switch (k) {
            '.' => Calculator.decimalPoint(s),
            '+' => Calculator.op(s, CalcOp.add),
            '-' => Calculator.op(s, CalcOp.subtract),
            '*' => Calculator.op(s, CalcOp.multiply),
            '/' => Calculator.op(s, CalcOp.divide),
            '%' => Calculator.percent(s),
            '=' => Calculator.equals(s),
            's' => Calculator.toggleSign(s),
            'c' => Calculator.clear(s),
            'b' => Calculator.backspace(s),
            _ => throw ArgumentError(k),
          };
  }
  return s;
}

String shown(String keys) => Calculator.display(run(keys));

void main() {
  group('basic operations', () {
    test('add, subtract, multiply, divide', () {
      expect(shown('12+30='), '42');
      expect(shown('5-8='), '-3');
      expect(shown('7*6='), '42');
      expect(shown('10/4='), '2.5');
    });

    test('decimals are exact: 0.1 + 0.2 = 0.3', () {
      expect(shown('.1+.2='), '0.3');
      expect(shown('1.1*3='), '3.3');
      expect(shown('0.3-0.1='), '0.2');
    });

    test('a chain is worked out left to right as typed', () {
      expect(shown('2+3*4='), '20');
      expect(shown('100-20-30='), '50');
    });

    test('one third shows ten decimals', () {
      expect(shown('1/3='), '0.3333333333');
      expect(shown('2/3='), '0.6666666667');
    });

    test('"=" again repeats the last operation', () {
      expect(shown('2+3=='), '8');
      expect(shown('10/2=='), '2.5');
    });

    test('two operators in a row: the second one counts', () {
      expect(shown('8+-3='), '5');
      expect(shown('8*/2='), '4');
    });

    test('a result can be continued, or replaced by typing', () {
      expect(shown('2+3=*10='), '50');
      expect(shown('2+3=7+1='), '8');
    });
  });

  group('per cent', () {
    test('alone it divides by 100', () {
      expect(shown('50%'), '0.5');
    });

    test('after + or − it is a share of the first number', () {
      expect(shown('200+10%='), '220');
      expect(shown('200-25%='), '150');
    });

    test('after × or ÷ it is the number over 100', () {
      expect(shown('200*10%='), '20');
      expect(shown('50/50%='), '100');
    });

    test('of a result', () {
      expect(shown('40+10=%'), '0.5');
    });
  });

  group('safety', () {
    test('dividing by zero shows a message, never Infinity or NaN', () {
      final CalcState s = run('5/0=');
      expect(s.error, CalcError.divideByZero);
      final CalcState z = run('0/0=');
      expect(z.error, CalcError.divideByZero);
      // The next digit starts afresh.
      expect(Calculator.display(run('5/0=7')), '7');
    });

    test('a result past 1e60 is refused as too large', () {
      final CalcState s = run('999999999999999*999999999999999=*999999999999999=*999999999999999=*999999999999999=');
      expect(s.error, CalcError.tooLarge);
    });

    test('at most 15 digits can be typed', () {
      expect(shown('1234567890123456789'), '123456789012345');
    });

    test('one decimal point only; a leading point reads 0.', () {
      expect(shown('1.2.3'), '1.23');
      expect(shown('.5'), '0.5');
      expect(shown('+.'), '0.');
    });

    test('no leading zeros', () {
      expect(shown('0007'), '7');
      expect(shown('0.07'), '0.07');
    });
  });

  group('keys', () {
    test('sign change', () {
      expect(shown('5s'), '-5');
      expect(shown('5ss'), '5');
      expect(shown('3+4=s'), '-7');
      expect(shown('10-s3='), '13');
    });

    test('backspace removes the last digit, not a result', () {
      expect(shown('123b'), '12');
      expect(shown('1bb'), '0');
      expect(shown('2+3=b'), '5');
    });

    test('AC clears everything', () {
      final CalcState s = run('12+3c');
      expect(s.accumulator, isNull);
      expect(s.pending, isNull);
      expect(Calculator.display(s), '0');
    });
  });

  group('display format', () {
    String fmt(String plain, {String group = ',', String decimal = '.'}) =>
        CalcFormat.format(plain, group: group, decimal: decimal);

    test("groups thousands with the user's separators", () {
      expect(fmt('1234567.5'), '1,234,567.5');
      expect(fmt('1234567.5', group: '.', decimal: ','), '1.234.567,5');
      expect(fmt('-1000'), '-1,000');
      expect(fmt('12.'), '12.');
    });

    test('long numbers switch to scientific notation and always fit', () {
      final String s = fmt('123456789012345678901234');
      expect(s, contains('e'));
      expect(s.length, lessThanOrEqualTo(CalcFormat.maxChars));
    });
  });

  test('in the Tools menu, free for everyone (no plan check)', () {
    expect(AppMenu.folds[NavFold.tools], contains(AppSection.calculator));
    expect(AppMenu.of(AppSection.calculator)?.route, '/calculator');
    expect(AppMenu.of(AppSection.calculator)?.icon, Icons.calculate_outlined);
  });

  Future<void> pump(WidgetTester tester,
      {String locale = 'en', bool dark = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: dark
            ? ThemeData.dark().copyWith(extensions: const <ThemeExtension<dynamic>>[
                DsColors.dark,
                DsGlass.dark,
              ])
            : ThemeData(extensions: const <ThemeExtension<dynamic>>[
                DsColors.light,
                DsGlass.light,
              ]),
        home: const Scaffold(body: CalculatorPage()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String display(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calc-display'))).data!;

  Future<void> tap(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('calc-$id')));
    await tester.pump();
  }

  testWidgets('works by touch: 1,250 × 3 = 3,750', (WidgetTester tester) async {
    await pump(tester);
    for (final String k in <String>['d1', 'd2', 'd5', 'd0']) {
      await tap(tester, k);
    }
    expect(display(tester), '1,250');
    await tap(tester, 'op-multiply');
    await tap(tester, 'd3');
    await tap(tester, 'equals');
    expect(display(tester), '3,750');
    await tap(tester, 'clear');
    expect(display(tester), '0');
  });

  testWidgets('dividing by zero says so in the dark theme',
      (WidgetTester tester) async {
    await pump(tester, dark: true);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tap(tester, 'd5');
    await tap(tester, 'op-divide');
    await tap(tester, 'd0');
    await tap(tester, 'equals');
    expect(display(tester), l.calcDivideByZero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in Arabic the page reads right to left, the keypad stays 7 8 9',
      (WidgetTester tester) async {
    await pump(tester, locale: 'ar');
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l.navCalculator), findsOneWidget);
    final double x7 = tester.getCenter(find.byKey(const Key('calc-d7'))).dx;
    final double x9 = tester.getCenter(find.byKey(const Key('calc-d9'))).dx;
    expect(x7, lessThan(x9));
    expect(tester.takeException(), isNull);
  });
}
