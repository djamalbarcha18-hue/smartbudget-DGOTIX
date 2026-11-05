import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/category_badge.dart';

void main() {
  test('every built-in category has its own icon style', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(CategoryStyle.hasStyle(c, t), isTrue, reason: '$t $c');
      }
    }
  });

  test('income categories use the income families, expenses never', () {
    for (final String c in Catalog.incomeCategories) {
      expect(
          CategoryStyle.of(c, TransactionType.income).family.isIncome, isTrue);
    }
    for (final String c in Catalog.expenseCategories) {
      expect(CategoryStyle.of(c, TransactionType.expense).family.isIncome,
          isFalse);
    }
  });

  test('a user-made category gets a neutral fallback', () {
    expect(CategoryStyle.hasStyle('my own', TransactionType.expense), isFalse);
    expect(CategoryStyle.of('my own', TransactionType.expense).family,
        CategoryFamily.commitments);
  });
}
