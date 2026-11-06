import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/transactions/application/category_icon_style.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/category_badge.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('colours by default; the choice is kept on the device', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(categoryIconsPlainProvider), isFalse);
    await c.read(categoryIconsPlainProvider.notifier).set(true);
    expect(c.read(categoryIconsPlainProvider), isTrue);

    final ProviderContainer again = ProviderContainer();
    addTearDown(again.dispose);
    again.read(categoryIconsPlainProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(again.read(categoryIconsPlainProvider), isTrue);
  });

  testWidgets('plain: the badge is grey, in colours it has its family colour',
      (WidgetTester tester) async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    Future<Color> iconColor() async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: DsTheme.light(),
          home: const Scaffold(
              body: CategoryBadge(
                  category: 'الطعام', type: TransactionType.expense)),
        ),
      ));
      await tester.pump();
      return tester.widget<Icon>(find.byType(Icon).first).color!;
    }

    final Color coloured = await iconColor();
    expect(coloured,
        familyColor(CategoryFamily.food, DsColors.light, Brightness.light));
    await c.read(categoryIconsPlainProvider.notifier).set(true);
    expect(await iconColor(), DsColors.light.textMuted);
  });
}
