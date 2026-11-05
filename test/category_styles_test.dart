import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/transactions/application/category_styles_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/category_badge.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('look encodes, decodes and rejects junk', () {
    final CustomCategoryLook? l = CustomCategoryLook.decode('cart|food');
    expect(l!.iconKey, 'cart');
    expect(l.familyName, 'food');
    expect(CustomCategoryLook.decode('nope'), isNull);
    expect(CustomCategoryLook.decode(null), isNull);
  });

  test('a picked look is saved, reloaded and removed', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(categoryStylesProvider);
    await c.read(categoryStylesProvider.notifier).set(TransactionType.expense,
        'Coffee', const CustomCategoryLook('coffee', 'food'));
    expect(c.read(categoryStylesProvider)['e:Coffee']!.iconKey, 'coffee');

    final ProviderContainer again = ProviderContainer();
    addTearDown(again.dispose);
    again.read(categoryStylesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(again.read(categoryStylesProvider)['e:Coffee']!.familyName, 'food');

    await again
        .read(categoryStylesProvider.notifier)
        .remove(TransactionType.expense, 'Coffee');
    expect(again.read(categoryStylesProvider), isEmpty);
  });

  testWidgets('the badge of a user-made category shows the picked icon',
      (WidgetTester tester) async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(categoryStylesProvider.notifier).set(TransactionType.expense,
        'Coffee', const CustomCategoryLook('coffee', 'food'));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: DsTheme.light(),
        home: const Scaffold(
            body: CategoryBadge(
                category: 'Coffee', type: TransactionType.expense)),
      ),
    ));
    expect(find.byIcon(pickableCategoryIcons['coffee']!), findsOneWidget);
  });

  test('every pickable icon key is unique and families exclude income', () {
    expect(pickableCategoryIcons.length, 24);
    expect(pickableFamilies, isNot(contains(CategoryFamily.income)));
  });
}
