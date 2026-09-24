import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/l10n/latin_digits.dart';

void main() {
  group('normalize', () {
    test('Eastern Arabic and Persian digits become Latin', () {
      expect(LatinDigits.normalize('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(LatinDigits.normalize('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('Arabic separators become . and , with the same length', () {
      const String typed = '١٬٢٣٤٫٥٠';
      final String out = LatinDigits.normalize(typed);
      expect(out, '1,234.50');
      expect(out.length, typed.length);
    });

    test('other text is left alone', () {
      expect(LatinDigits.normalize('إيجار 700 USD'), 'إيجار 700 USD');
      expect(LatinDigits.normalize(''), '');
    });
  });

  test('dates format with Latin digits even in native-digit locales', () async {
    await initializeDateFormatting('ar_EG');
    final DateTime d = DateTime(2026, 9, 24);
    expect(DateFormat('d/M/y', 'ar_EG').format(d), contains('٢٠٢٦'));
    LatinDigits.enforce();
    final String out = DateFormat('d MMMM y', 'ar_EG').format(d);
    expect(out, contains('24'));
    expect(out, contains('2026'));
    expect(RegExp('[٠-٩]').hasMatch(out), isFalse);
  });
}
