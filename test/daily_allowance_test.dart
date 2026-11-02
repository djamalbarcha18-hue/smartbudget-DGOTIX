import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:smartbudget/features/budget/domain/daily_allowance.dart';
import 'package:smartbudget/features/dashboard/presentation/dashboard_cards.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

const String _cur = 'DZD';

/// Widget tests draw every glyph as a box, which is fine for assertions and
/// useless for a picture. The capture below loads the app's own Arabic font
/// and sets this; everywhere else it stays null and nothing changes.
String? _shotFont;

/// Makes [family] available to the test renderer from real font files.
Future<void> _loadFont(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in paths) {
    loader.addFont(
        File(path).readAsBytes().then((Uint8List b) => b.buffer.asByteData()));
  }
  await loader.load();
}

Money _m(int major) => Money(major * 100, _cur);

/// The category the budget below is set on.
const String _budgeted = 'food';

/// The card as the dashboard builds it, at the width a phone gives it.
///
/// [spent] went to the budgeted category; [elsewhere] to one with no budget,
/// which the card must leave out of the comparison.
Widget _host({
  required Money planned,
  required Money spent,
  Money? elsewhere,
  Locale locale = const Locale('ar'),
}) =>
    ProviderScope(
      overrides: <Override>[
        baseCurrencyProvider.overrideWith(() => _Cur()),
        monthPlannedByCategoryProvider
            .overrideWithValue(<String, Money>{_budgeted: planned}),
        monthExpenseCategoryTotalsProvider.overrideWithValue(<CategoryTotal>[
          CategoryTotal(category: _budgeted, amount: spent),
          if (elsewhere != null)
            CategoryTotal(category: 'rent', amount: elsewhere),
        ]),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
            fontFamily: _shotFont,
            extensions: const <ThemeExtension<dynamic>>[
              DsColors.light,
              DsGlass.light,
            ]),
        home: const Scaffold(
          backgroundColor: Color(0xFFF2F4F7),
          body: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: 358,
                height: 150,
                child: BudgetPulseCard(),
              ),
            ),
          ),
        ),
      ),
    );

class _Cur extends BaseCurrencyController {
  @override
  String build() => _cur;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('what is left to spend each day', () {
    test('today counts, and the last day of the month leaves one', () {
      expect(DailyAllowance.daysLeftInMonth(DateTime(2026, 1, 28)), 4);
      expect(DailyAllowance.daysLeftInMonth(DateTime(2026, 1, 31)), 1);
      expect(DailyAllowance.daysLeftInMonth(DateTime(2026, 1, 1)), 31);
      // A short month, and a leap February.
      expect(DailyAllowance.daysLeftInMonth(DateTime(2026, 4, 1)), 30);
      expect(DailyAllowance.daysLeftInMonth(DateTime(2028, 2, 1)), 29);
    });

    test('no budget: no figure at all, rather than zero', () {
      expect(DailyAllowance.perDay(_m(0), _m(0), DateTime(2026, 1, 10)), null);
    });

    test('what is left, spread over the days that are left', () {
      // 15,000 left over 20 days (the 12th of a 31-day month).
      final Money? d =
          DailyAllowance.perDay(_m(30000), _m(15000), DateTime(2026, 1, 12));
      expect(d!.minorUnits, (15000 * 100 / 20).floor());
    });

    test('spending more today lowers the figure, not just the bar', () {
      final DateTime day = DateTime(2026, 1, 12);
      final Money calm = DailyAllowance.perDay(_m(30000), _m(10000), day)!;
      final Money loose = DailyAllowance.perDay(_m(30000), _m(20000), day)!;
      expect(loose.minorUnits, lessThan(calm.minorUnits));
    });

    test('overspent: zero for today, never a negative figure', () {
      final Money d =
          DailyAllowance.perDay(_m(30000), _m(34000), DateTime(2026, 1, 12))!;
      expect(d.minorUnits, 0);
      // How far past is kept, for the caption to say it.
      expect(DailyAllowance.left(_m(30000), _m(34000)).minorUnits, -4000 * 100);
    });
  });

  group('the budget card', () {
    testWidgets('without a budget it asks for one instead of showing a figure',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(planned: _m(0), spent: _m(0)));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      expect(find.text('—'), findsOneWidget);
      expect(find.text(l.budgetNotSet), findsOneWidget);
    });

    testWidgets('within the budget: today\'s figure, what is left and the days',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(planned: _m(30000), spent: _m(15000)));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      expect(find.text(l.budgetDailyTitle), findsOneWidget);
      // The headline is the daily figure, not a percentage.
      expect(find.textContaining('%'), findsNothing);
      final int days = DailyAllowance.daysLeftInMonth(AppClock.now());
      expect(find.textContaining(l.chDaysLeft(days)), findsOneWidget);
    });

    testWidgets('a budget on one category ignores what was spent outside it',
        (WidgetTester tester) async {
      // Food budgeted at 30,000 with 15,000 spent on it; the rent is far
      // bigger but was never in that budget, so it must not report an
      // overspend.
      await tester.pumpWidget(
          _host(planned: _m(30000), spent: _m(15000), elsewhere: _m(90000)));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      expect(find.textContaining(l.budgetOverBy('').trim().split(' ').first),
          findsNothing);
      final int days = DailyAllowance.daysLeftInMonth(AppClock.now());
      expect(find.textContaining(l.chDaysLeft(days)), findsOneWidget);
    });

    testWidgets('overspent: it says by how much, with no minus sign',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(planned: _m(30000), spent: _m(34000)));
      await tester.pumpAndSettle();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      expect(find.textContaining(l.budgetOverBy('').trim().split(' ').first),
          findsOneWidget);
      expect(find.textContaining('-'), findsNothing);
    });
  });

  // Pictures of the card for review; not an assertion.
  testWidgets('capture', (WidgetTester tester) async {
    const String dir = String.fromEnvironment('SHOTS');
    if (dir.isEmpty) return;
    const String sdk = String.fromEnvironment('ICONS');
    await tester.runAsync(() async {
      await _loadFont('SbTajawal', <String>[
        'assets/fonts/Tajawal-Regular.ttf',
        'assets/fonts/Tajawal-Bold.ttf',
      ]);
      if (sdk.isNotEmpty) await _loadFont('MaterialIcons', <String>[sdk]);
    });
    _shotFont = 'SbTajawal';
    addTearDown(() => _shotFont = null);
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final (String name, Money planned, Money spent, Locale loc)
        in <(String, Money, Money, Locale)>[
      ('ar-within', _m(30000), _m(15000), const Locale('ar')),
      ('ar-over', _m(30000), _m(34000), const Locale('ar')),
      ('ar-none', _m(0), _m(0), const Locale('ar')),
      ('en-within', _m(30000), _m(15000), const Locale('en')),
    ]) {
      await tester
          .pumpWidget(_host(planned: planned, spent: spent, locale: loc));
      await tester.pumpAndSettle();
      final RenderRepaintBoundary b =
          tester.renderObject(find.byType(RepaintBoundary).last);
      final Uint8List png = (await tester.runAsync(() async {
        final ui.Image img = await b.toImage(pixelRatio: 3);
        final ByteData? d =
            await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        return d!.buffer.asUint8List();
      }))!;
      File('$dir/budget-$name.png').writeAsBytesSync(png);
    }
  });
}
