import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/invoice_amounts.dart';

double? v(InvoiceNumberFormat f, String s, {int d = 2, bool q = false}) =>
    f.read(s, currencyDecimals: d, quantity: q)?.value;

void main() {
  group('number format of the invoice', () {
    test('a comma decimal invoice (French / Algerian)', () {
      final InvoiceNumberFormat f =
          InvoiceNumberFormat.detect(<String>['12,99', '1 250,50', '3,60']);
      expect(f.decimalMark, ',');
      expect(f.decided, isTrue);
    });

    test('a dot decimal invoice (English)', () {
      final InvoiceNumberFormat f =
          InvoiceNumberFormat.detect(<String>[r'$12.99', '1,250.50']);
      expect(f.decimalMark, '.');
    });

    test('only ambiguous amounts: undecided', () {
      final InvoiceNumberFormat f =
          InvoiceNumberFormat.detect(<String>['1.250', '2,500']);
      expect(f.decided, isFalse);
    });

    test('3-decimal currencies vote with 3 digits', () {
      final InvoiceNumberFormat f = InvoiceNumberFormat.detect(
          <String>['1.250', '0.500'],
          currencyDecimals: 3);
      expect(f.decimalMark, '.');
      expect(f.decided, isTrue);
    });
  });

  group('reading amounts', () {
    const InvoiceNumberFormat dot =
        InvoiceNumberFormat(decimalMark: '.', decided: true);
    const InvoiceNumberFormat comma =
        InvoiceNumberFormat(decimalMark: ',', decided: true);
    const InvoiceNumberFormat unknown =
        InvoiceNumberFormat(decimalMark: '.', decided: false);

    test('every printed style', () {
      expect(v(dot, '1,250.50'), 1250.50);
      expect(v(comma, '1 250,50'), 1250.50);
      expect(v(dot, '1250.50'), 1250.50);
      expect(v(comma, '1250,50'), 1250.50);
      expect(v(dot, r'$12.99'), 12.99);
      expect(v(dot, '12.99 USD'), 12.99);
      expect(v(comma, '12,99 €'), 12.99);
      expect(v(comma, '1 250 DA'), 1250);
      expect(v(unknown, '1,250 DZD'), 1250);
      expect(v(comma, '1.250.000,00'), 1250000);
      expect(v(dot, '1,250,000'), 1250000);
      expect(v(comma, '1 250,50'), 1250.50, reason: 'narrow no-break');
      expect(v(dot, "1'250.50"), 1250.50, reason: 'Swiss grouping');
      expect(v(comma, '١٢٥٠٫٥٠'), 1250.50, reason: 'Arabic-Indic digits');
    });

    test('1.250 and 1,250 depend on the invoice', () {
      // Comma-decimal invoice: "1.250" groups thousands.
      expect(v(comma, '1.250'), 1250);
      // Dot-decimal invoice: "1.250" is 1.25, "1,250" is 1250.
      expect(v(dot, '1.250'), 1.25);
      expect(v(dot, '1,250'), 1250);
      // Unknown format: thousands, unless the currency has 3 decimals.
      expect(v(unknown, '1.250'), 1250);
      expect(v(unknown, '1.250', d: 3), 1.25);
      // The other reading stays available for the checks.
      expect(dot.read('1.250')!.alternative, 1250);
    });

    test('quantities: weights and multipliers', () {
      expect(v(comma, '0,750', q: true), 0.75);
      expect(v(dot, '2', q: true), 2);
      expect(v(dot, 'x3', q: true), 3);
      expect(v(dot, '1.5 kg', q: true), 1.5);
    });

    test('negative amounts (discounts) and empty text', () {
      expect(v(dot, '-3.12'), -3.12);
      expect(v(comma, '(3,12)'), -3.12);
      expect(v(comma, '3,12-'), -3.12);
      expect(dot.read(''), isNull);
      expect(dot.read('TOTAL'), isNull);
      expect(dot.read(null), isNull);
    });
  });
}
