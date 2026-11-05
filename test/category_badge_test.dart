import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/category_badge.dart';

void main() {
  contrastTests();
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

void contrastTests() {
  double lin(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  double ratio(Color a, Color b) {
    final double x = lum(a), y = lum(b);
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  test('every family icon is readable on its badge in every theme', () {
    final Map<DsColors, Brightness> themes = <DsColors, Brightness>{
      DsColors.light: Brightness.light,
      DsColors.beige: Brightness.light,
      DsColors.sage: Brightness.light,
      DsColors.pomegranate: Brightness.light,
      DsColors.dark: Brightness.dark,
      DsColors.black: Brightness.dark,
    };
    themes.forEach((DsColors c, Brightness b) {
      for (final CategoryFamily f in CategoryFamily.values) {
        final Color fg = familyColor(f, c, b);
        final Color bg =
            Color.alphaBlend(fg.withValues(alpha: kBadgeTint), c.surface);
        expect(ratio(fg, bg), greaterThanOrEqualTo(3.0), reason: '$f $b');
      }
    });
  });
}
