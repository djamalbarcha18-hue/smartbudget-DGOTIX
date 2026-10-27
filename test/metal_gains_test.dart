import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metal_editor_sheet.dart';
import 'package:smartbudget/features/metals/presentation/metals_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A pure gram of gold at 12,000 DZD and of silver at 150 DZD.
const Map<Metal, MetalPrice> _prices = <Metal, MetalPrice>{
  Metal.gold: MetalPrice(
      perGram: 12000, currency: 'DZD', source: MetalPriceSource.market),
  Metal.silver: MetalPrice(
      perGram: 150, currency: 'DZD', source: MetalPriceSource.market),
};

const Map<String, double> _rates = <String, double>{
  'USD': 1,
  'DZD': 135,
  'EUR': 0.9,
};

MetalHolding _h(String id, Metal m, double grams, int purity,
        {int? paid, String currency = 'DZD', DateTime? on}) =>
    MetalHolding(
      id: id,
      metal: m,
      grams: grams,
      purity: purity,
      paid: paid == null ? null : Money(paid * 100, currency),
      boughtOn: on,
      createdAt: DateTime(2026, 10, 1),
    );

/// Bought at different times and prices: 10 g of 21 karat (8.75 g pure,
/// worth 105,000 today) in 2023 for 80,000, the same in 2025 for 100,000,
/// a silver bar in 2025, and a ring with no price.
final List<MetalHolding> _lots = <MetalHolding>[
  _h('g23', Metal.gold, 10, 21, paid: 80000, on: DateTime(2023, 3, 10)),
  _h('g25', Metal.gold, 10, 21, paid: 100000, on: DateTime(2025, 6, 1)),
  _h('s25', Metal.silver, 100, 999, paid: 12000, on: DateTime(2025, 6, 1)),
  _h('ring', Metal.gold, 4, 18),
];

int _minor(Money m) => m.minorUnits;

/// The rates above, fixed.
class _FixedRates extends RatesController {
  @override
  Map<String, double> build() => _rates;
}

void main() {
  group('each purchase keeps its own result', () {
    test('cheap long ago and dear lately, side by side', () {
      final Gain old =
          MetalGains.ofHolding(_lots[0], _prices[Metal.gold], _rates)!;
      final Gain recent =
          MetalGains.ofHolding(_lots[1], _prices[Metal.gold], _rates)!;
      expect(_minor(old.value), 10500000);
      expect(_minor(old.amount), 2500000);
      expect(old.ratio, closeTo(0.3125, 1e-9));
      expect(_minor(recent.amount), 500000);
      expect(recent.ratio, closeTo(0.05, 1e-9));
    });

    test('no price paid: no result, and it is counted as such', () {
      expect(
          MetalGains.ofHolding(_lots[3], _prices[Metal.gold], _rates), isNull);
      expect(MetalGains.withoutCost(_lots), 1);
    });

    test('a cost in another currency is converted', () {
      // 600 EUR = 90,000 DZD at these rates.
      final Gain g = MetalGains.ofHolding(
          _h('e', Metal.gold, 10, 21, paid: 600, currency: 'EUR'),
          _prices[Metal.gold],
          _rates)!;
      expect(_minor(g.paid), 9000000);
      expect(_minor(g.amount), 1500000);
    });
  });

  test('the average cost of a pure gram, per metal', () {
    final Map<Metal, MetalAverage> a =
        MetalGains.averages(_lots, _prices, 'DZD', _rates);
    // 180,000 for 17.5 pure grams; the ring has no cost and stays out.
    expect(a[Metal.gold]!.pureGrams, closeTo(17.5, 1e-9));
    expect(_minor(a[Metal.gold]!.paid), 18000000);
    expect(a[Metal.gold]!.paidPerGram.asDouble, closeTo(10285.71, 0.01));
    expect(a[Metal.gold]!.todayPerGram.asDouble, 12000);
    expect(a[Metal.silver]!.paidPerGram.asDouble, closeTo(120.12, 0.01));
  });

  test('grouped by the year bought, newest first', () {
    final List<YearGain> years =
        MetalGains.byYear(_lots, _prices, 'DZD', _rates);
    expect(years.map((YearGain y) => y.year), <int>[2025, 2023]);
    // 2025: gold 100,000 + silver 12,000 → 105,000 + 14,985.
    expect(years[0].count, 2);
    expect(_minor(years[0].gain.paid), 11200000);
    expect(_minor(years[0].gain.value), 11998500);
    expect(_minor(years[1].gain.amount), 2500000);
    // The years add up to the overall result.
    final MetalsSummary s =
        MetalsValuation.summarize(_lots, _prices, 'DZD', _rates);
    expect(years.fold<int>(0, (int t, YearGain y) => t + _minor(y.gain.paid)),
        _minor(s.paidTotal!.paid));
    expect(years.fold<int>(0, (int t, YearGain y) => t + _minor(y.gain.value)),
        _minor(s.paidTotal!.value));
  });

  group('a period on the chart', () {
    MetalPoint p(int day, int value, int? paid) => MetalPoint(
        day: DateTime(2026, 10, day),
        minor: value,
        currency: 'DZD',
        paid: paid);

    test('a purchase is never taken for a gain', () {
      // Day 2: a 60,000 bar is bought; day 3: the price rises.
      final Gain g = MetalGains.overPeriod(<MetalPoint>[
        p(1, 100000, 90000),
        p(2, 160000, 150000),
        p(3, 168000, 150000),
      ])!;
      expect(g.amount.minorUnits, 8000);
      expect(g.ratio, closeTo(0.05, 1e-9));
      // Only the purchase: nothing gained.
      expect(
          MetalGains.overPeriod(
                  <MetalPoint>[p(1, 100000, 90000), p(2, 160000, 150000)])!
              .amount
              .minorUnits,
          0);
    });

    test('a sale is not a loss either', () {
      final Gain g = MetalGains.overPeriod(<MetalPoint>[
        p(1, 160000, 150000),
        p(2, 100000, 90000),
      ])!;
      expect(g.amount.minorUnits, 0);
    });

    test('days noted before costs were known are left out', () {
      expect(
          MetalGains.overPeriod(
              <MetalPoint>[p(1, 100000, null), p(2, 110000, null)]),
          isNull);
      final Gain g = MetalGains.overPeriod(<MetalPoint>[
        p(1, 50000, null),
        p(2, 100000, 90000),
        p(3, 110000, 90000),
      ])!;
      expect(g.amount.minorUnits, 10000);
    });

    test('what was paid is kept with each day', () {
      final MetalPoint a = p(5, 123, 100);
      expect(MetalPoint.fromJson(a.toJson())!.paid, 100);
      expect(MetalPoint.fromJson(p(5, 123, null).toJson())!.paid, isNull);
      // Days noted by the earlier version still read.
      expect(
          MetalPoint.fromJson(<String, dynamic>{
            'd': '2026-10-05',
            'v': 123,
            'c': 'DZD',
          })!
              .paid,
          isNull);
    });
  });

  group('workmanship', () {
    // 10 g of 21 karat for 120,000, of which 30,000 workmanship; worth
    // 105,000 in metal today.
    final MetalHolding bracelet = MetalHolding(
      id: 'b',
      metal: Metal.gold,
      grams: 10,
      purity: 21,
      paid: const Money(12000000, 'DZD'),
      making: const Money(3000000, 'DZD'),
      createdAt: DateTime(2026, 1, 1),
    );

    test('the result counts everything paid; the metal alone is apart', () {
      final Gain g =
          MetalGains.ofHolding(bracelet, _prices[Metal.gold], _rates)!;
      expect(g.amount.minorUnits, -1500000); // workmanship is spent
      expect(g.ratio, closeTo(-0.125, 1e-9));
      expect(g.making!.minorUnits, 3000000);
      final Gain metal = g.metalOnly!;
      expect(metal.amount.minorUnits, 1500000); // the gold itself rose
      expect(metal.ratio, closeTo(1 / 6, 1e-9));
    });

    test('the average price of a gram leaves workmanship out', () {
      final MetalAverage a = MetalGains.averages(
          <MetalHolding>[bracelet], _prices, 'DZD', _rates)[Metal.gold]!;
      expect(a.paidPerGram.asDouble, closeTo(90000 / 8.75, 0.01));
    });

    test('kept with the piece, and older pieces still read', () {
      final MetalHolding back = MetalHolding.fromJson(bracelet.toJson());
      expect(back.making, const Money(3000000, 'DZD'));
      expect(MetalHolding.fromJson(_lots[0].toJson()).making, isNull);
    });
  });

  group('paid in another currency', () {
    // 600 EUR that came to 85,000 DZD on the day (today's rate: 90,000).
    final MetalHolding abroad = MetalHolding(
      id: 'a',
      metal: Metal.gold,
      grams: 10,
      purity: 21,
      paid: const Money(60000, 'EUR'),
      paidBase: const Money(8500000, 'DZD'),
      createdAt: DateTime(2026, 1, 1),
    );

    test("what it came to then counts, not today's rate", () {
      final Gain g = MetalGains.ofHolding(abroad, _prices[Metal.gold], _rates)!;
      expect(g.paid.minorUnits, 8500000);
      expect(g.amount.minorUnits, 2000000);
    });

    test('kept with the piece', () {
      expect(MetalHolding.fromJson(abroad.toJson()).paidBase,
          const Money(8500000, 'DZD'));
    });

    test('a piece paid in the base currency needs nothing more', () {
      expect(MetalsValuation.cost(_lots[0], 'DZD', _rates), _lots[0].paid);
    });
  });

  testWidgets('adding: currency, what it came to, workmanship',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_base_currency': 'DZD',
    });
    tester.view.physicalSize = const Size(1170, 5000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      metalPricesProvider.overrideWithValue(_prices),
      ratesProvider.overrideWith(_FixedRates.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
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
        home: const Scaffold(body: MetalEditorSheet()),
      ),
    ));
    await tester.pumpAndSettle();
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    final String base = c.read(baseCurrencyProvider);
    // Simple at first: no extra fields.
    expect(find.text(l.metalsPaidInBase(base)), findsNothing);
    expect(find.text(l.metalsFieldMaking), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).at(2), '600');
    // Paid in euros: what it came to appears, filled in at today's rate.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();
    expect(find.text(l.metalsPaidInBase(base)), findsOneWidget);
    final double rate = _rates[base]! / _rates['EUR']!;
    expect(find.text(AmountInput.text(600 * rate)), findsOneWidget);
    // The user knows better: their own figure that day.
    await tester.enterText(find.byType(TextFormField).at(3), '85000');

    // Workmanship: opened on demand; more than paid is refused.
    await tester.tap(find.text(l.metalsAddMaking));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(4), '700');
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    expect(find.text(l.metalsMakingTooHigh), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(4), '100');
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();

    final MetalHolding saved = (await tester
        .runAsync(() => c.read(metalStoreProvider).all()))!.single;
    expect(saved.paid, const Money(60000, 'EUR'));
    expect(saved.paidBase, Money.fromDouble(85000, base));
    expect(saved.making, const Money(10000, 'EUR'));
  });

  testWidgets('the page: each piece, the average and the years',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_base_currency': 'DZD',
    });
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      metalPricesProvider.overrideWithValue(_prices),
      metalHoldingsProvider
          .overrideWith((Ref ref) => Stream<List<MetalHolding>>.value(_lots)),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
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
        home: const Scaffold(body: MetalsPage()),
      ),
    ));
    await tester.pumpAndSettle();
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    // Each piece: its own share (the 2023 piece also makes up its year).
    expect(find.textContaining('+31.3%'), findsNWidgets(2));
    expect(find.textContaining('+5.0%'), findsWidgets);
    // The piece with no price says so, and is counted apart.
    expect(find.textContaining(l.metalsNoCost), findsOneWidget);
    expect(find.text(l.metalsNoCostNote(1)), findsOneWidget);
    // The average cost of a pure gram against today's.
    expect(find.textContaining('12,000'), findsWidgets);
    // Two years of purchases: the card by year.
    expect(find.text(l.metalsByYear), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
