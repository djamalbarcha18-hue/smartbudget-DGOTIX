import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_duplicates.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

InvoiceReading read({String inv = 'A-1', String sup = 'GlobalMart'}) =>
    InvoiceAnalyzer.analyze(<String, dynamic>{
      'inv': inv, 'dt': '2026-09-05', 'cur': 'USD', 'sym': 'USD', 'sup': sup,
      'it': <Map<String, dynamic>>[
        <String, dynamic>{'n': 'Milk', 'q': '2', 'u': '2.49', 't': '4.98', 'c': 0.9},
      ],
      'tot': '4.98',
    }, today: DateTime(2026, 10, 2));

void main() {
  test('same invoice number and supplier: likely duplicate', () {
    expect(
        InvoiceDuplicates.isLikelyDuplicate(read(),
            previous: <InvoiceFingerprint>[InvoiceFingerprint.of(read())]),
        isTrue);
    expect(
        InvoiceDuplicates.isLikelyDuplicate(read(inv: 'A-2'),
            previous: <InvoiceFingerprint>[InvoiceFingerprint.of(read())]),
        isFalse);
  });

  test('no invoice number: date, supplier, total and item count together', () {
    final InvoiceReading a = read(inv: '');
    expect(
        InvoiceDuplicates.isLikelyDuplicate(a,
            previous: <InvoiceFingerprint>[InvoiceFingerprint.of(read(inv: ''))]),
        isTrue);
    expect(
        InvoiceDuplicates.isLikelyDuplicate(a,
            previous: <InvoiceFingerprint>[
              InvoiceFingerprint.of(read(inv: '', sup: 'Other shop'))
            ]),
        isFalse);
  });

  test('an expense already recorded that day for the same amount', () {
    final RecordedExpense same = RecordedExpense(
        date: DateTime(2026, 9, 5, 18), amount: 4.98, currency: 'USD',
        description: 'GlobalMart');
    expect(InvoiceDuplicates.isLikelyDuplicate(read(),
        expenses: <RecordedExpense>[same]), isTrue);
    final RecordedExpense otherDay = RecordedExpense(
        date: DateTime(2026, 9, 6), amount: 4.98, currency: 'USD');
    expect(InvoiceDuplicates.isLikelyDuplicate(read(),
        expenses: <RecordedExpense>[otherDay]), isFalse);
    final RecordedExpense otherShop = RecordedExpense(
        date: DateTime(2026, 9, 5), amount: 4.98, currency: 'USD',
        description: 'Pharmacy');
    expect(InvoiceDuplicates.isLikelyDuplicate(read(),
        expenses: <RecordedExpense>[otherShop]), isFalse);
  });
}
