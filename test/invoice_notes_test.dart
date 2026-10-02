import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_notes.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 2);

  test('items, discount and tax become the expense note', () {
    final InvoiceReading r = InvoiceAnalyzer.analyze(<String, dynamic>{
      'inv': 'GM-1', 'cur': 'USD', 'sym': 'USD',
      'it': <Map<String, dynamic>>[
        <String, dynamic>{'n': 'Milk 1L', 'q': '2', 'u': '2.49', 't': '4.98', 'c': 0.9},
        <String, dynamic>{'n': 'Bread', 'q': '', 'u': '', 't': '3.60', 'c': 0.9},
      ],
      'sub': '8.58', 'dis': '0.58', 'tax': '0.80', 'tot': '8.80',
    }, today: today);
    expect(InvoiceNotes.of(r),
        '# GM-1\n• Milk 1L  2 × 2.49 = 4.98\n• Bread  3.60\n− 0.58 · + 0.80');
  });

  test('long invoices are cut with a count', () {
    final InvoiceReading r = InvoiceAnalyzer.analyze(<String, dynamic>{
      'it': <Map<String, dynamic>>[
        for (int i = 0; i < 60; i++)
          <String, dynamic>{'n': 'Item $i', 'q': '1', 'u': '1.00', 't': '1.00', 'c': 0.9},
      ],
      'tot': '60.00',
    }, today: today);
    final List<String> lines = InvoiceNotes.of(r)!.split('\n');
    expect(lines.length, InvoiceNotes.maxLines);
    expect(lines.last, '… +21');
  });

  test('nothing to note: null', () {
    final InvoiceReading r =
        InvoiceAnalyzer.analyze(<String, dynamic>{'tot': '5.00'}, today: today);
    expect(InvoiceNotes.of(r), isNull);
  });
}
