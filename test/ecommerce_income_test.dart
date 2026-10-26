import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 27);
  QuickEntry p(String s) => QuickEntryParser.parse(s, today: today)!;

  test('e-commerce is an income category', () {
    expect(Catalog.incomeCategories, contains('تجارة إلكترونية'));
  });

  test("a shop's earnings, in a few languages", () {
    for (final String s in <String>[
      'مبيعات المتجر 1200',
      'أرباح المتجر 300',
      'shopify 250',
      'amazon payout 480',
      'vente en ligne 90',
      'jualan online 150rb',
      'tienda online 75',
      'интернет-магазин 5000',
      '网店收入 800',
    ]) {
      final QuickEntry e = p(s);
      expect(e.category, 'تجارة إلكترونية', reason: s);
      expect(e.type, TransactionType.income, reason: s);
    }
  });

  test('buying on a shop is still shopping', () {
    final QuickEntry e = p('amazon 60');
    expect(e.category, 'التسوق');
    expect(e.type, TransactionType.expense);
  });
}
