import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';
import 'package:smartbudget/features/receipts/domain/offline_receipt_parser.dart';

/// OCR output: each entry is a row of (left x, text) pieces at row [i] —
/// ML Kit returns the name and the price of a line as separate boxes.
List<OcrLine> ocr(List<List<(double, String)>> rows) => <OcrLine>[
      for (int i = 0; i < rows.length; i++)
        for (final (double x, String t) in rows[i])
          OcrLine(t, left: x, right: x + 100, top: i * 30.0 + (x % 3), bottom: i * 30.0 + 20 + (x % 3)),
    ]..shuffle();

void main() {
  final DateTime today = DateTime(2026, 10, 2);

  test('a French supermarket receipt', () {
    final Map<String, dynamic> raw = OfflineReceiptParser.parse(ocr(<List<(double, String)>>[
      <(double, String)>[(10, 'SUPERETTE EL BARAKA')],
      <(double, String)>[(10, 'Tél: 021 23 45 67')],
      <(double, String)>[(10, 'Facture N° FA-2026-0412'), (300, '05/09/2026 18:42')],
      <(double, String)>[(10, 'Désignation  Qté  P.U  Montant')],
      <(double, String)>[(10, 'Lait 1L'), (200, '2'), (260, '120,00'), (330, '240,00')],
      <(double, String)>[(10, 'Pain'), (200, '5'), (260, '15,00'), (330, '75,00')],
      <(double, String)>[(10, 'Café moulu 250g'), (330, '450,00')],
      <(double, String)>[(10, 'Huile 5L'), (200, '1'), (230, '1 250,00'), (330, '1 250,00')],
      <(double, String)>[(10, 'TOTAL TTC'), (330, '2 015,00 DA')],
      <(double, String)>[(10, 'Espèces'), (330, '2 100,00')],
      <(double, String)>[(10, 'Rendu'), (330, '85,00')],
      <(double, String)>[(10, 'Merci de votre visite')],
    ]));
    expect(raw['sup'], 'SUPERETTE EL BARAKA');
    expect(raw['inv'], 'FA-2026-0412');
    expect(raw['dt'], '2026-09-05');
    expect(raw['sym'], 'DA');
    expect(raw['tot'], '2 015,00');
    expect(raw['paid'], '2 100,00');
    final List<dynamic> it = raw['it'] as List<dynamic>;
    expect(it.map((dynamic i) => i['n']), <String>['Lait 1L', 'Pain', 'Café moulu 250g', 'Huile 5L']);

    // Through the same checks as the cloud reading.
    final InvoiceReading r = InvoiceAnalyzer.analyze(raw, today: today);
    expect(r.currency, 'DZD');
    expect(r.total, 2015);
    expect(r.items[0].quantity, 2);
    expect(r.items[0].unitPrice, 120);
    expect(r.items[3].lineTotal, 1250);
    expect(r.checks.itemsSumMatchesSubtotal, isTrue);
    expect(r.checks.issues, isNot(contains(InvoiceIssue.lineMismatch)));
    // Read on the device: the user is asked to glance at it.
    expect(r.level(), isNot(ReviewLevel.verified));
  });

  test('an English receipt with tax, and a name and amounts on two lines', () {
    final Map<String, dynamic> raw = OfflineReceiptParser.parse(ocr(<List<(double, String)>>[
      <(double, String)>[(10, 'GlobalMart')],
      <(double, String)>[(10, 'www.globalmart.com')],
      <(double, String)>[(10, 'Receipt #GM-4582'), (300, '2026-09-05')],
      <(double, String)>[(10, 'Milk 1L 2 x'), (260, '2.49'), (330, '4.98')],
      <(double, String)>[(10, 'Organic whole wheat bread')],
      <(double, String)>[(200, '3'), (260, '1.20'), (330, '3.60')],
      <(double, String)>[(10, 'Subtotal'), (330, '8.58')],
      <(double, String)>[(10, 'Tax 8%'), (330, '0.69')],
      <(double, String)>[(10, 'TOTAL'), (330, r'$9.27')],
      <(double, String)>[(10, 'VISA **** **** **** 1111')],
      <(double, String)>[(10, 'Thank you!')],
    ]));
    expect(raw['inv'], 'GM-4582');
    expect(raw['sub'], '8.58');
    expect(raw['tax'], '0.69');
    expect(raw['tot'], '9.27');
    final List<dynamic> it = raw['it'] as List<dynamic>;
    expect(it.length, 2);
    expect(it[0]['n'], 'Milk 1L');
    expect(it[0]['q'], '2');
    expect(it[1]['n'], 'Organic whole wheat bread');
    expect(it[1]['q'], '3');

    final InvoiceReading r = InvoiceAnalyzer.analyze(raw, today: today);
    expect(r.total, closeTo(9.27, 1e-9));
    expect(r.checks.totalMatchesCalculation, isTrue);
    expect(r.checks.itemsSumMatchesSubtotal, isTrue);
  });

  test('nothing is invented when the OCR misses things', () {
    final Map<String, dynamic> raw = OfflineReceiptParser.parse(ocr(<List<(double, String)>>[
      <(double, String)>[(10, 'Article'), (330, '12,50')],
      <(double, String)>[(10, 'TOTAL'), (330, '12,50')],
    ]));
    expect(raw['dt'], '');
    expect(raw['inv'], '');
    expect((raw['it'] as List<dynamic>).single['q'], '');
    final InvoiceReading r = InvoiceAnalyzer.analyze(raw, today: today);
    expect(r.date, isNull);
    expect(r.items.single.quantity, isNull);
    expect(r.total, 12.5);
  });
}
