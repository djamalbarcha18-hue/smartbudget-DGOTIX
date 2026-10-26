import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/quick_entry/presentation/quick_entry_sheet.dart';
import 'package:smartbudget/features/transactions/data/fake_transaction_repository.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pump(WidgetTester tester,
      {List<Override> overrides = const <Override>[]}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final ProviderContainer c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
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
    QuickEntrySheet.show(nav.currentContext!);
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('a pasted bank message becomes one entry, saved as it says',
      (WidgetTester tester) async {
    final ProviderContainer c = await pump(tester);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(
        find.byType(TextField),
        'Purchase of USD 120.50 at CARREFOUR on 01/03/2024.\n'
        'Available balance: USD 3,450.00');
    await tester.pumpAndSettle();
    expect(find.text(l.pasteSmsRead), findsOneWidget);
    expect(find.textContaining('CARREFOUR'), findsWidgets);
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final Transaction t =
        (await c.read(financeRepositoryProvider).watchAll().first).single;
    expect(t.amount.asDouble, 120.5);
    expect(t.type, TransactionType.expense);
    expect(t.category, 'الطعام');
    expect(<int>[t.date.year, t.date.month, t.date.day], <int>[2024, 3, 1]);
  });

  testWidgets('ordinary quick entry is unchanged', (WidgetTester tester) async {
    final ProviderContainer c = await pump(tester);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(find.byType(TextField), 'coffee 3.5; taxi 12');
    await tester.pumpAndSettle();
    expect(find.text(l.pasteSmsRead), findsNothing);
    await tester.tap(find.text(l.quickSaveN(2)));
    await tester.pumpAndSettle();
    expect(
        await c.read(financeRepositoryProvider).watchAll().first, hasLength(2));
  });

  testWidgets('a double tap on Save records the entry once',
      (WidgetTester tester) async {
    // A store that takes a moment to write, like the phone's storage.
    final _SlowRepository slow = _SlowRepository();
    final ProviderContainer c = await pump(tester, overrides: <Override>[
      financeRepositoryProvider.overrideWithValue(slow),
    ]);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(find.byType(TextField), 'coffee 3.5');
    await tester.pumpAndSettle();
    // The second tap lands while the first save is still writing.
    await tester.tap(find.text(l.save));
    await tester.tap(find.text(l.save), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(slow.current, hasLength(1));
    expect(c.read(financeRepositoryProvider), same(slow));
  });
}

class _SlowRepository extends FakeTransactionRepository {
  _SlowRepository() : super(userId: 'slow');

  @override
  Future<void> add(Transaction txn) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await super.add(txn);
  }
}
