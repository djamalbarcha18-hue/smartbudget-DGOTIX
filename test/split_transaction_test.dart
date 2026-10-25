import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  String label(String category) => Catalog.label(category, lang: AppLang.en);

  Future<(ProviderContainer, AppLocalizations)> open(
      WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 5000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    // Keep the list loaded, as the app's screens do.
    c.listen(transactionsProvider, (_, __) {});
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: const Scaffold(body: SizedBox()),
      ),
    ));
    TransactionEditorSheet.show(nav.currentContext!,
        type: TransactionType.expense);
    await tester.pumpAndSettle();
    return (c, await AppLocalizations.delegate.load(const Locale('en')));
  }

  Future<void> pick(WidgetTester tester, Finder dropdown, String item) async {
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label(item)).last);
    await tester.pumpAndSettle();
  }

  Finder dropdowns() => find.byType(DropdownButtonFormField<String>);

  testWidgets('a supermarket receipt: food, home, a gift; the rest is food',
      (WidgetTester tester) async {
    final (ProviderContainer c, AppLocalizations l) = await open(tester);
    await tester.enterText(find.byType(TextFormField).first, '120');
    await pick(tester, dropdowns().first, 'الطعام');
    // Amount, then description, before the split lines.
    await tester.enterText(find.byType(TextFormField).at(1), 'Supermarket');

    await tester.tap(find.text(l.splitAction));
    await tester.pumpAndSettle();
    await pick(tester, dropdowns().at(1), 'الأثاث والمنزل');
    await tester.enterText(
        find.widgetWithText(TextFormField, l.fieldAmount).last, '30');
    await tester.tap(find.text(l.splitAddLine));
    await tester.pumpAndSettle();
    await pick(tester, dropdowns().at(2), 'الهدايا');
    await tester.enterText(
        find.widgetWithText(TextFormField, l.fieldAmount).last, '50');
    await tester.pumpAndSettle();
    expect(find.text(l.splitRest), findsOneWidget);
    expect(find.textContaining('40.00'), findsOneWidget);
    // A split is saved once: no repeating.
    expect(find.text(l.fieldRepeat), findsNothing);

    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final List<Transaction> saved = c.read(transactionsProvider).value!;
    expect(saved.length, 3);
    final Map<String, double> byCategory = <String, double>{
      for (final Transaction t in saved) t.category: t.amount.asDouble,
    };
    expect(byCategory, <String, double>{
      'الطعام': 40,
      'الأثاث والمنزل': 30,
      'الهدايا': 50,
    });
    expect(saved.map((Transaction t) => t.splitId).toSet().length, 1);
    expect(saved.first.splitId, isNotNull);
    expect(
        saved.every((Transaction t) => t.description == 'Supermarket'), isTrue);
    expect(saved.map((Transaction t) => t.date).toSet().length, 1);
  });

  testWidgets('parts reaching the whole amount are not saved',
      (WidgetTester tester) async {
    final (ProviderContainer c, AppLocalizations l) = await open(tester);
    await tester.enterText(find.byType(TextFormField).first, '20');
    await pick(tester, dropdowns().first, 'الطعام');
    await tester.tap(find.text(l.splitAction));
    await tester.pumpAndSettle();
    await pick(tester, dropdowns().at(1), 'الهدايا');
    await tester.enterText(
        find.widgetWithText(TextFormField, l.fieldAmount).last, '25');
    await tester.pumpAndSettle();
    expect(find.text(l.splitTooMuch), findsOneWidget);
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    expect(
        c.read(transactionsProvider).value ?? const <Transaction>[], isEmpty);

    // Not splitting after all: one expense of the whole amount.
    await tester.tap(find.text(l.splitCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final Transaction t = c.read(transactionsProvider).value!.single;
    expect(t.amount, const Money(2000, 'USD'));
    expect(t.splitId, isNull);
  });

  test('the split id travels in backups and sync', () {
    final Transaction t = Transaction(
      id: 'a-0',
      date: DateTime(2026, 10, 25),
      type: TransactionType.expense,
      category: 'الطعام',
      amount: const Money(4000, 'SAR'),
      splitId: 'a',
      createdAt: DateTime(2026, 10, 25),
    );
    expect(Transaction.fromJson(t.toJson()).splitId, 'a');
    expect(t.copyWith(category: 'الهدايا').splitId, 'a');
    expect(
        Transaction.fromJson(<String, dynamic>{
          ...t.toJson()..remove('splitId'),
        }).splitId,
        isNull);
  });
}
