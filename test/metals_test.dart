import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/metals/presentation/metals_page.dart';
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

    final MetalHolding saved = c.read(metalHoldingsProvider).value!.single;
    expect(saved.grams, 50);
    expect(saved.purity, 21);
    expect(find.textContaining('13,125.00'), findsWidgets);
  });
}
