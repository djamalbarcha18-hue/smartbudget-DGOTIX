import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_alert.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metal_art.dart';
import 'package:smartbudget/features/metals/presentation/metals_home_card.dart';
import 'package:smartbudget/features/metals/presentation/metals_page.dart';
import 'package:smartbudget/features/notifications/domain/notification_feed.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  MetalHolding h(String id, Metal m, double g, int p, {Money? paid}) =>
      MetalHolding(
          id: id,
          metal: m,
          grams: g,
          purity: p,
          paid: paid,
          createdAt: DateTime(2026));

  group('valuation', () {
    test('karats and fineness: the share of pure metal', () {
      expect(Metal.gold.fraction(24), 1);
      expect(Metal.gold.fraction(21), 0.875);
      expect(Metal.gold.fraction(18), 0.75);
      expect(Metal.silver.fraction(925), 0.925);
      expect(Metal.palladium.fraction(950), 0.95);
      expect(Metal.palladium.symbol, 'XPD');
      expect(h('a', Metal.gold, 40, 18).pureGrams, 30);
    });

    test('the world price per ounce in dollars, per gram in riyals', () {
      // $2,400 an ounce, 3.75 riyals a dollar: 289.36 riyals a gram.
      expect(
          MetalsValuation.marketPerGram(
              2400, 'SAR', const <String, double>{'SAR': 3.75}),
          closeTo(289.3567, 0.0001));
      expect(
          MetalsValuation.marketPerGram(2400, 'USD', const <String, double>{}),
          closeTo(77.1618, 0.0001));
      expect(
          MetalsValuation.marketPerGram(
              null, 'SAR', const <String, double>{'SAR': 3.75}),
          isNull);
      expect(
          MetalsValuation.marketPerGram(2400, 'XYZ', const <String, double>{}),
          isNull);
    });

    test('a 50 g bracelet of 21 karat at 300 a gram is 13,125', () {
      const MetalPrice p = MetalPrice(
          perGram: 300, currency: 'SAR', source: MetalPriceSource.market);
      expect(MetalsValuation.value(h('a', Metal.gold, 50, 21), p),
          const Money(1312500, 'SAR'));
    });

    test('totals per metal, pure grams, the gain, and a metal with no price',
        () {
      final MetalsSummary s = MetalsValuation.summarize(
        <MetalHolding>[
          h('g1', Metal.gold, 50, 21,
              paid: const Money(1200000, 'SAR')), // 13,125 now
          h('g2', Metal.gold, 10, 24), // 3,000
          h('s', Metal.silver, 100, 925), // 925
          h('p', Metal.platinum, 5, 950), // no price
        ],
        const <Metal, MetalPrice>{
          Metal.gold: MetalPrice(
              perGram: 300, currency: 'SAR', source: MetalPriceSource.market),
          Metal.silver: MetalPrice(
              perGram: 10, currency: 'SAR', source: MetalPriceSource.mine),
        },
        'SAR',
        const <String, double>{'SAR': 3.75},
      );
      expect(s.total, const Money(1705000, 'SAR'));
      expect(s.byMetal[Metal.gold], const Money(1612500, 'SAR'));
      expect(s.byMetal[Metal.silver], const Money(92500, 'SAR'));
      expect(s.pureGrams[Metal.gold], closeTo(53.75, 1e-9));
      expect(s.pureGrams[Metal.platinum], closeTo(4.75, 1e-9));
      expect(s.unpriced, <Metal>{Metal.platinum});
      // Only the bracelet has a cost: 12,000 paid, 13,125 now.
      expect(s.paidTotal!.paid, const Money(1200000, 'SAR'));
      expect(s.paidTotal!.value, const Money(1312500, 'SAR'));
    });

    test('a cost paid in another currency counts at today’s rate', () {
      final MetalsSummary s = MetalsValuation.summarize(
        <MetalHolding>[
          h('g', Metal.gold, 10, 24, paid: const Money(80000, 'USD')),
        ],
        const <Metal, MetalPrice>{
          Metal.gold: MetalPrice(
              perGram: 300, currency: 'SAR', source: MetalPriceSource.market),
        },
        'SAR',
        const <String, double>{'USD': 1, 'SAR': 3.75},
      );
      expect(s.paidTotal!.paid, const Money(300000, 'SAR'));
    });
  });

  group('storage', () {
    test('a holding survives JSON, an unknown karat falls back', () {
      final MetalHolding a =
          h('a', Metal.gold, 12.5, 22, paid: const Money(450000, 'SAR'));
      final MetalHolding b = MetalHolding.fromJson(a.toJson());
      expect(b.grams, 12.5);
      expect(b.purity, 22);
      expect(b.paid, const Money(450000, 'SAR'));
      expect(
          MetalHolding.fromJson(const <String, dynamic>{
            'id': 'x',
            'metal': 'silver',
            'grams': 5,
            'purity': 17,
          }).purity,
          925);
    });

    test('holdings are in backups and in sync', () {
      final BackupData d = BackupData(
        exportedAt: DateTime(2026),
        baseCurrency: 'SAR',
        transactions: const [],
        budgets: const [],
        customIncome: const <String>[],
        customExpense: const <String>[],
        metals: <MetalHolding>[h('a', Metal.silver, 100, 999)],
      );
      final BackupData back = BackupCodec.decodeJson(BackupCodec.encodeJson(d));
      expect(back.metals.single.grams, 100);
      expect(SyncMerge.listCollections, contains('metals'));
      expect(SyncMerge.recordsFromBackup(d.toJson())['metals']!.keys,
          <String>['a']);
    });
  });

  testWidgets('add a gold bracelet; its value shows at the price used',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_base_currency': 'SAR',
    });
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      metalPricesProvider.overrideWithValue(const <Metal, MetalPrice>{
        Metal.gold: MetalPrice(
            perGram: 300, currency: 'SAR', source: MetalPriceSource.market),
      }),
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
    expect(find.text(l.metalsEmptyTitle), findsOneWidget);

    await tester.tap(find.text(l.metalsAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.text(l.metalKarat(21)));
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();

    // Platinum and palladium wait folded under industrial metals.
    expect(find.text(l.tabIndustrialMetals), findsOneWidget);
    expect(find.text('${l.metalPlatinum} · 999'), findsNothing);
    await tester.ensureVisible(find.text(l.tabIndustrialMetals));
    await tester.tap(find.text(l.tabIndustrialMetals));
    await tester.pumpAndSettle();
    expect(find.text('${l.metalPlatinum} · 999'), findsOneWidget);

    final MetalHolding saved = c.read(metalHoldingsProvider).value!.single;
    expect(saved.grams, 50);
    expect(saved.purity, 21);
    expect(find.textContaining('13,125.00'), findsWidgets);

    // Today's value is noted for the chart.
    await tester.pumpAndSettle();
    final MetalPoint today = c.read(metalHistoryProvider).single;
    expect(today.minor, 1312500);
    expect(today.currency, 'SAR');

    // A price alert on gold: 290 is below today's 300, so it waits for a fall.
    await tester.tap(find.byTooltip(l.metalsAlert).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '290');
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final MetalAlert alert = c.read(metalAlertsProvider).single;
    expect(alert.metal, Metal.gold);
    expect(alert.above, isFalse);
    expect(find.textContaining(l.metalsAlertBelow('')), findsOneWidget);
    expect(c.read(metalAlertNoticesProvider), isEmpty);
  });

  group('history', () {
    MetalPoint p(int day, int v, [String c = 'SAR']) =>
        MetalPoint(day: DateTime(2026, 10, day), minor: v, currency: c);

    test('one point a day, the latest wins, oldest first', () {
      List<MetalPoint> list =
          MetalHistory.record(const <MetalPoint>[], p(3, 10));
      list = MetalHistory.record(list, p(1, 5));
      list = MetalHistory.record(list, p(3, 12));
      expect(list.map((MetalPoint x) => x.minor), <int>[5, 12]);
      expect(
          MetalPoint.fromJson(list.last.toJson())!.day, DateTime(2026, 10, 3));
      expect(MetalPoint.fromJson(<String, Object>{'d': 'x', 'v': 1}), isNull);
    });

    test('a range keeps its own currency and days', () {
      final List<MetalPoint> all = <MetalPoint>[
        p(1, 1),
        p(20, 2, 'USD'),
        p(25, 3),
      ];
      expect(
          MetalHistory.series(all, 'SAR', DateTime(2026, 10, 26), days: 10)
              .map((MetalPoint x) => x.minor),
          <int>[3]);
      expect(MetalHistory.series(all, 'SAR', DateTime(2026, 10, 26)).length, 2);
    });

    test('noted at start-up, before the saved days are read: none is lost',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_metal_history_guest': '[{"d":"2026-01-01","v":500,"c":"SAR"}]',
      });
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(metalHistoryProvider); // starts loading
      await c.read(metalHistoryProvider.notifier).record(
          MetalsValuation.summarize(
              <MetalHolding>[h('a', Metal.gold, 1, 24)],
              const <Metal, MetalPrice>{
                Metal.gold: MetalPrice(
                    perGram: 300,
                    currency: 'SAR',
                    source: MetalPriceSource.market),
              },
              'SAR',
              const <String, double>{}),
          1);
      expect(c.read(metalHistoryProvider).map((MetalPoint p) => p.minor),
          <int>[500, 30000]);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sb_metal_history_guest'), contains('500'));
    });

    test('about two years are kept', () {
      List<MetalPoint> list = const <MetalPoint>[];
      for (int i = 0; i < MetalHistory.keep + 5; i++) {
        list = MetalHistory.record(
            list,
            MetalPoint(
                day: DateTime(2024, 1, 1 + i), minor: i, currency: 'SAR'));
      }
      expect(list.length, MetalHistory.keep);
      expect(list.first.minor, 5);
    });
  });

  group('price alerts', () {
    const MetalPrice at300 = MetalPrice(
        perGram: 300, currency: 'SAR', source: MetalPriceSource.market);

    test('met when the price rises or falls to the target, in its currency',
        () {
      const MetalAlert up = MetalAlert(
          metal: Metal.gold, target: 300, currency: 'SAR', above: true);
      const MetalAlert down = MetalAlert(
          metal: Metal.gold, target: 290, currency: 'SAR', above: false);
      expect(up.metBy(at300), isTrue);
      expect(down.metBy(at300), isFalse);
      expect(
          up.metBy(const MetalPrice(
              perGram: 900, currency: 'AED', source: MetalPriceSource.market)),
          isFalse);
      expect(MetalAlert.fromJson(up.toJson())!.above, isTrue);
      expect(MetalAlert.fromJson(<String, Object>{'metal': 'gold'}), isNull);
    });

    test('a met alert rings the bell once, and only while it holds', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        metalPricesProvider
            .overrideWithValue(const <Metal, MetalPrice>{Metal.gold: at300}),
      ]);
      addTearDown(c.dispose);
      expect(c.read(metalAlertNoticesProvider), isEmpty);
      await c
          .read(metalAlertsProvider.notifier)
          .set(Metal.gold, 295, 'SAR', current: 280);
      final List<AppAlert> notices = c.read(metalAlertNoticesProvider);
      expect(notices.single.kind, AlertKind.metalPrice);
      expect(notices.single.route, '/metals');
      expect(notices.single.subject, 'metal:gold');
      expect(notices.single.compareAmount, const Money(29500, 'SAR'));
      final String id = NotificationFeed.idFor(notices.single, DateTime(2026));
      expect(NotificationFeed.idFor(notices.single, DateTime(2027)), id);

      // Only one alert per metal; removing it quiets the bell.
      await c.read(metalAlertsProvider.notifier).set(Metal.gold, null, 'SAR');
      expect(c.read(metalAlertsProvider), isEmpty);
      expect(c.read(metalAlertNoticesProvider), isEmpty);
    });
  });

  group('home card', () {
    Future<ProviderContainer> pump(
        WidgetTester tester, List<MetalHolding> holdings,
        {bool masked = false,
        Map<Metal, MetalPrice> prices = const <Metal, MetalPrice>{
          Metal.gold: MetalPrice(
              perGram: 300, currency: 'SAR', source: MetalPriceSource.market),
        }}) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_base_currency': 'SAR',
      });
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        metalHoldingsProvider.overrideWith(
            (Ref ref) => Stream<List<MetalHolding>>.value(holdings)),
        metalPricesProvider.overrideWithValue(prices),
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
          home: Scaffold(
            body: MoneyPrivacy(
              masked: masked,
              onToggle: () {},
              hideLabel: 'hide',
              showLabel: 'show',
              peekHint: 'peek',
              child: const MetalsHomeCard(),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('no metal kept: gold and silver of today, a way in',
        (WidgetTester tester) async {
      await pump(tester, const <MetalHolding>[]);
      expect(find.byType(MetalPlate), findsOneWidget);
      expect(find.textContaining('300.00'), findsOneWidget);
      expect(find.byTooltip('hide'), findsNothing); // nothing of theirs
    });

    testWidgets('nothing at all without prices or metals',
        (WidgetTester tester) async {
      await pump(tester, const <MetalHolding>[],
          prices: const <Metal, MetalPrice>{});
      expect(find.byType(MetalPlate), findsNothing);
    });

    testWidgets("today's value and the change since bought",
        (WidgetTester tester) async {
      await pump(tester, <MetalHolding>[
        h('a', Metal.gold, 10, 24, paid: const Money(250000, 'SAR')),
      ]);
      expect(find.byType(MetalPlate), findsOneWidget);
      expect(find.textContaining('3,000.00'), findsOneWidget);
      expect(find.textContaining('+20.0%'), findsOneWidget);
    });

    testWidgets('amounts hidden: the mask, no value, no change',
        (WidgetTester tester) async {
      await pump(
          tester,
          <MetalHolding>[
            h('a', Metal.gold, 10, 24, paid: const Money(250000, 'SAR')),
          ],
          masked: true);
      expect(find.text(MoneyPrivacy.mask), findsOneWidget);
      expect(find.textContaining('3,000.00'), findsNothing);
      expect(find.textContaining('+20.0%'), findsNothing);
      expect(find.byTooltip('show'), findsOneWidget);
    });
  });
}
