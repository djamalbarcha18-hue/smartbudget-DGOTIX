import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LatinDigits.enforce();
  });

  Future<ProviderContainer> pump(
      WidgetTester tester, Locale locale, Widget child) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        navigatorKey: nav,
        home: const SizedBox(),
      ),
    ));
    // Opened over a page, as in the app: saving closes it.
    nav.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => Scaffold(body: child)));
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> typeDate(
      WidgetTester tester, Locale locale, DateTime shown, String typed) async {
    final Finder tile = find.text(dayText(locale, shown));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    final MaterialLocalizations m =
        MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
    await tester.tap(find.byTooltip(m.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextField)),
        typed);
    await tester.tap(find.text(m.okButtonLabel));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, AppLocalizations l) async {
    await tester.ensureVisible(find.text(l.save));
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
  }

  for (final Locale locale in const <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
    Locale('ru'),
  ]) {
    testWidgets('$locale: type 2026/10/25, save, reload, edit, export',
        (WidgetTester tester) async {
      final AppLocalizations l = await AppLocalizations.delegate.load(locale);
      final ProviderContainer c = await pump(
          tester,
          locale,
          const TransactionEditorSheet(
            type: TransactionType.expense,
            prefill: TransactionDraft(amount: 42, category: 'المطاعم'),
          ));

      await typeDate(tester, locale, AppClock.now(), '2026/10/25');
      expect(
          find.text(dayText(locale, DateTime(2026, 10, 25))), findsOneWidget);
      await save(tester, l);

      final Transaction saved =
          (await c.read(financeRepositoryProvider).watchAll().first).single;
      expect(<int>[saved.date.year, saved.date.month, saved.date.day],
          <int>[2026, 10, 25]);
      expect(saved.amount, Money.fromDouble(42, saved.amount.currencyCode));

      // Reload from storage, as after a restart or a sync.
      final Transaction reloaded = Transaction.fromJson(saved.toJson());
      expect(reloaded.date, saved.date);
      // Export keeps the day.
      expect(BackupCodec.transactionsToCsv(<Transaction>[reloaded]),
          contains('2026-10-25'));

      // Edit: the stored day is shown, another typed day replaces it.
      await pump(
          tester,
          locale,
          TransactionEditorSheet(
              type: TransactionType.expense, existing: reloaded));
      expect(
          find.text(dayText(locale, DateTime(2026, 10, 25))), findsOneWidget);
      await typeDate(tester, locale, DateTime(2026, 10, 25), '2024/02/29');
      expect(find.text(dayText(locale, DateTime(2024, 2, 29))), findsOneWidget);
    });
  }

  testWidgets('Today and Yesterday shortcuts', (WidgetTester tester) async {
    const Locale locale = Locale('en');
    final AppLocalizations l = await AppLocalizations.delegate.load(locale);
    final ProviderContainer c = await pump(
        tester,
        locale,
        const TransactionEditorSheet(
          type: TransactionType.expense,
          prefill: TransactionDraft(amount: 5, category: 'المطاعم'),
        ));
    final DateTime now = AppClock.now();
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    ChoiceChip chip(String label) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
    // A new entry is for today.
    expect(chip(l.quickToday).selected, isTrue);
    expect(chip(l.quickYesterday).selected, isFalse);

    await tester.ensureVisible(find.text(l.quickYesterday));
    await tester.tap(find.text(l.quickYesterday));
    await tester.pumpAndSettle();
    expect(chip(l.quickYesterday).selected, isTrue);
    expect(find.text(dayText(locale, yesterday)), findsOneWidget);
    await save(tester, l);

    final Transaction saved =
        (await c.read(financeRepositoryProvider).watchAll().first).single;
    expect(DateUtils.dateOnly(saved.date), yesterday);
  });
}
