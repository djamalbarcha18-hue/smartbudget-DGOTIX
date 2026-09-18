import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/dev/sample_data.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

void main() {
  group('SampleData.build', () {
    test('covers all 12 months of the target year', () {
      final SampleDataSet s = SampleData.build(currency: 'USD', year: 2026);
      final Set<int> months =
          s.transactions.map((Transaction t) => t.date.month).toSet();
      expect(months, <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12});
      expect(s.transactions.every((Transaction t) => t.date.year == 2026),
          isTrue);
      expect(s.budgets.every((b) => b.year == 2026), isTrue);
    });

    test('is idempotent — stable ids repeat across builds', () {
      final SampleDataSet a = SampleData.build(currency: 'USD');
      final SampleDataSet b = SampleData.build(currency: 'USD');
      expect(
        a.transactions.map((Transaction t) => t.id).toSet(),
        b.transactions.map((Transaction t) => t.id).toSet(),
      );
      // Ids are unique within a build.
      expect(a.transactions.map((Transaction t) => t.id).toSet().length,
          a.transactions.length);
    });

    test('uses only real catalog categories', () {
      final SampleDataSet s = SampleData.build(currency: 'USD');
      for (final Transaction t in s.transactions) {
        final List<String> valid = t.isIncome
            ? Catalog.incomeCategories
            : Catalog.expenseCategories;
        expect(valid.contains(t.category), isTrue,
            reason: 'unknown category: ${t.category}');
      }
    });

    test('amounts are in the requested currency', () {
      final SampleDataSet s = SampleData.build(currency: 'EUR');
      expect(
        s.transactions.every((Transaction t) => t.amount.currencyCode == 'EUR'),
        isTrue,
      );
    });
  });
}
