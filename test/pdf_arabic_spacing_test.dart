import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/reports/data/report_pdf.dart';

void main() {
  group('Arabic word gaps in the PDF', () {
    test('a gap is widened so the library cannot swallow it', () {
      expect(pdfSafe('دار السلام'), 'دار  السلام');
      expect(pdfSafe('الادخار والاستثمار'), 'الادخار  والاستثمار');
      expect(pdfSafe('إيجار السكن'), 'إيجار  السكن');
    });

    test('every gap in a longer name, not just the first', () {
      expect(pdfSafe('مكافأة نهاية الخدمة'), 'مكافأة  نهاية  الخدمة');
    });

    test('Persian and Urdu too', () {
      expect(pdfSafe('خانه و مبلمان'), 'خانه  و  مبلمان');
      expect(pdfSafe('گھر اور فرنیچر'), 'گھر  اور  فرنیچر');
    });

    test('other scripts are left exactly as they are', () {
      for (final String s in <String>[
        'Rent and bills',
        'Loyer et factures',
        'Аренда и счета',
        '住房与账单',
      ]) {
        expect(pdfSafe(s), s, reason: s);
      }
    });

    test('running it twice changes nothing', () {
      const String s = 'الادخار والاستثمار';
      expect(pdfSafe(pdfSafe(s)), pdfSafe(s));
    });

    test('a single word is untouched', () {
      expect(pdfSafe('راتب'), 'راتب');
    });

    test('direction marks are still removed', () {
      // A money string carries an isolate so the symbol stays in front on
      // screen; the PDF fonts have no glyph for it.
      expect(pdfSafe('\u2066100.00 د.ج\u2069'), '100.00  د.ج');
      expect(pdfSafe('\u200E\u200F'), '');
    });

    test('a mixed line widens only because it has Arabic in it', () {
      expect(
          pdfSafe('SmartBudget — تقرير سنوي'), 'SmartBudget  —  تقرير  سنوي');
    });
  });
}
