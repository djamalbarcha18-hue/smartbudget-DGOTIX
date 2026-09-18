import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

void main() {
  group('ScannedReceipt.fromCloudJson', () {
    test('parses a well-formed payload', () {
      final ScannedReceipt r = ScannedReceipt.fromCloudJson(<String, dynamic>{
        'merchant_name': '  Carrefour  ',
        'date': '2026-03-10',
        'total_amount': 42.5,
        'currency': 'eur',
        'category': 'التسوق',
        'confidence': 0.91,
      });
      expect(r.merchantName, 'Carrefour');
      expect(r.date, DateTime.parse('2026-03-10'));
      expect(r.totalAmount, 42.5);
      expect(r.currency, 'EUR');
      expect(r.category, 'التسوق');
      expect(r.confidence, 0.91);
      expect(r.fromCloud, isTrue);
    });

    test('tolerates string numbers and missing/empty date', () {
      final ScannedReceipt r = ScannedReceipt.fromCloudJson(<String, dynamic>{
        'merchant_name': 'Shop',
        'date': '',
        'total_amount': '19,90',
        'currency': 'USD',
        'category': 'الطعام',
        'confidence': '0.5',
      });
      expect(r.date, isNull);
      expect(r.totalAmount, 19.90);
      expect(r.confidence, 0.5);
    });

    test('clamps confidence and defaults missing numbers to zero', () {
      final ScannedReceipt r = ScannedReceipt.fromCloudJson(<String, dynamic>{
        'merchant_name': 'X',
        'date': null,
        'total_amount': null,
        'currency': '',
        'category': '',
        'confidence': 5,
      });
      expect(r.totalAmount, 0);
      expect(r.confidence, 1.0);
      expect(r.currency, '');
    });
  });
}
