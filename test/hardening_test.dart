import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/router/app_router.dart';

void main() {
  group('return after sign-in', () {
    test('keeps an in-app page, with its query', () {
      expect(safeReturnPath('/reports'), '/reports');
      expect(safeReturnPath('/trips/abc?tab=2'), '/trips/abc?tab=2');
    });

    test('never another site, the splash or a sign-in page', () {
      for (final String? bad in <String?>[
        null,
        '',
        'reports',
        '//evil.example/x',
        'https://evil.example',
        '/\\evil.example',
        '/',
        '/login',
        '/signup?x=1',
        '/forgot',
      ]) {
        expect(safeReturnPath(bad), isNull, reason: '$bad');
      }
    });
  });

  group('a currency the app does not list', () {
    test('keeps its own code instead of becoming US dollars', () {
      final Currency c = Currencies.byCode('XYZ');
      expect(c.code, 'XYZ');
      expect(c.symbol, 'XYZ');
      expect(Currencies.isKnown('XYZ'), isFalse);
      expect(Money(1250, 'XYZ').currency.code, 'XYZ');
    });

    test('listed currencies are unchanged', () {
      expect(Currencies.byCode('DZD').code, 'DZD');
      expect(Currencies.byCode('CLP').decimals, 0);
      expect(Currencies.isKnown('EUR'), isTrue);
    });
  });
}
