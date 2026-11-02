import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/presentation/markets_page.dart';
import 'package:smartbudget/features/monthly_budget/presentation/monthly_budget_page.dart';
import 'package:smartbudget/features/shell/app_top_bar.dart';
import 'package:smartbudget/features/shell/brand_controls.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/first_entry_buttons.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class _Ars extends BaseCurrencyController {
  @override
  String build() => 'ARS';
}

class _Sar extends BaseCurrencyController {
  @override
  String build() => 'SAR';
}

final Set<ProviderContainer> _disposed = <ProviderContainer>{};
void _dispose(ProviderContainer c) {
  if (_disposed.add(c)) c.dispose();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppLocalizations l;

  Future<ProviderContainer> pump(WidgetTester tester, Widget child,
      {List<Override> overrides = const <Override>[],
      Size size = const Size(1170, 4000),
      bool settle = true,
      Locale locale = const Locale('en')}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: overrides);
    addTearDown(() => _dispose(c));
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
        home: Scaffold(body: child),
      ),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
    l = await AppLocalizations.delegate.load(locale);
    return c;
  }

  testWidgets('a phone bar fits: month and year are one chip, one picker',
      (WidgetTester tester) async {
    final ProviderContainer c = await pump(
        tester, const AppTopBar(onOpenMenu: null),
        size: const Size(1080, 2400)); // 360 wide: a small phone
    expect(tester.takeException(), isNull);
    final int year = AppClock.now().year;
    await tester.tap(find.textContaining('$year'));
    await tester.pumpAndSettle();
    // Next year, then March: both are set at once.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('March'));
    await tester.pumpAndSettle();
    expect(c.read(selectedYearProvider), year + 1);
    expect(c.read(selectedMonthProvider), 3);
    expect(find.text('March ${year + 1}'), findsOneWidget);
    // The app's background timers (clock sync) go with the container.
    await tester.pumpWidget(const SizedBox());
    _dispose(c);
    await tester.pump(const Duration(minutes: 1));
  });

  for (final (String name, Size size) in <(String, Size)>[
    ('the smallest phone', const Size(960, 2400)), // 320 wide
    ('a desktop', const Size(4200, 2400)), // 1400 wide
  ]) {
    testWidgets('light/dark sits by search and notifications on $name',
        (WidgetTester tester) async {
      final ProviderContainer c =
          await pump(tester, const AppTopBar(onOpenMenu: null), size: size);
      expect(tester.takeException(), isNull);
      final Finder theme = find.byType(ThemeToggleButton);
      expect(theme, findsOneWidget);
      final Finder dark = find.descendant(
          of: theme, matching: find.byIcon(Icons.dark_mode_outlined));
      final bool wasDark = dark.evaluate().isEmpty;
      final double x = tester.getCenter(theme).dx;
      final double bell = tester
          .getCenter(find.byIcon(Icons.notifications_none_rounded))
          .dx;
      expect(x, lessThan(bell));
      expect(bell - x, lessThan(60)); // right beside it
      if (size.width < 1200) {
        expect(tester.getCenter(find.byIcon(Icons.search_rounded)).dx,
            lessThan(x)); // phone: search, then light/dark
      }
      await tester.tap(theme);
      await tester.pumpAndSettle();
      // The other mode now: the icon offers the way back.
      expect(dark.evaluate().isEmpty, !wasDark);
      await tester.pumpWidget(const SizedBox());
      _dispose(c);
      await tester.pump(const Duration(minutes: 1));
    });
  }

  testWidgets('nothing recorded: the transactions page offers to start',
      (WidgetTester tester) async {
    await pump(tester, const TransactionsListView());
    expect(find.byType(FirstEntryButtons), findsOneWidget);
    expect(find.text(l.addExpense), findsOneWidget);
    expect(find.text(l.addIncome), findsOneWidget);
  });

  testWidgets('a new expense: amount first, notes and payment folded',
      (WidgetTester tester) async {
    await pump(
        tester, const TransactionEditorSheet(type: TransactionType.expense));
    expect(find.textContaining(l.fieldNotes), findsNothing);
    expect(find.textContaining(l.fieldPaymentMethod), findsNothing);
    await tester.tap(find.text(l.txnMoreDetails));
    await tester.pumpAndSettle();
    expect(find.textContaining(l.fieldNotes), findsOneWidget);
    expect(find.textContaining(l.fieldPaymentMethod), findsWidgets);
  });

  testWidgets('notes already there (a scanned receipt): shown, not folded',
      (WidgetTester tester) async {
    await pump(
        tester,
        const TransactionEditorSheet(
          type: TransactionType.expense,
          prefill: TransactionDraft(notes: 'Bread x2'),
        ));
    expect(find.text('Bread x2'), findsOneWidget);
    expect(find.text(l.txnMoreDetails), findsNothing);
  });

  testWidgets(
      'the budget shows the everyday categories and those in use; '
      'the rest folded', (WidgetTester tester) async {
    late List<String> cats;
    final ProviderContainer probe = ProviderContainer();
    cats = probe.read(categoriesForProvider(TransactionType.expense));
    probe.dispose();
    final String late = cats.last; // far down the list
    // In Arabic, where the category names are the stored ones.
    await pump(tester, const MonthlyBudgetPage(),
        settle: false,
        locale: const Locale('ar'),
        size: const Size(2400, 6000), // the test font is wider than the app's
        overrides: <Override>[
          transactionsProvider.overrideWith((Ref ref) =>
              Stream<List<Transaction>>.value(const <Transaction>[])),
          monthPlannedByCategoryProvider.overrideWithValue(
              <String, Money>{late: const Money(50000, 'USD')}),
        ]);
    expect(find.text(cats.first), findsOneWidget);
    expect(find.text(late), findsOneWidget); // has a budget: not folded
    final String folded = cats[cats.length - 2];
    expect(find.text(folded), findsNothing);
    final int hidden = cats.length - 7;
    await tester.tap(find.text(l.budgetMoreCategories(hidden)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(folded), findsOneWidget);
  });

  group('markets by country', () {
    final List<Override> offline = <Override>[
      fxSnapshotProvider.overrideWith((Ref ref) async => throw 'offline'),
      parallelQuotesProvider
          .overrideWith((Ref ref, String _) async => <FxQuote>[]),
    ];

    testWidgets('your own market first, the others folded',
        (WidgetTester tester) async {
      await pump(tester, const MarketsPage(), overrides: <Override>[
        ...offline,
        baseCurrencyProvider.overrideWith(_Ars.new),
      ]);
      expect(find.text('Argentina'), findsOneWidget);
      expect(find.text('Algeria'), findsNothing);
      expect(find.text(l.marketsOtherCountries(3)), findsOneWidget);
      // Nothing came back: said once, not under every figure.
      expect(find.text(l.marketUnavailable), findsOneWidget);
    });

    testWidgets('no market of your own: all folded, no country put first',
        (WidgetTester tester) async {
      await pump(tester, const MarketsPage(), overrides: <Override>[
        ...offline,
        baseCurrencyProvider.overrideWith(_Sar.new),
      ]);
      for (final String country in <String>[
        'Algeria',
        'Argentina',
        'Lebanon',
        'Nigeria'
      ]) {
        expect(find.text(country), findsNothing);
      }
      expect(find.text(l.marketsByCountry(4)), findsOneWidget);
    });
  });
}
