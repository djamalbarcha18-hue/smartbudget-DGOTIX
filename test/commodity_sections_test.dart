import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/presentation/commodity_sections.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

CommodityQuote _q(String code, String name,
        {double? price,
        double? previous,
        String? period,
        bool monthly = false,
        String source = 'IMF'}) =>
    CommodityQuote(
      code: code,
      nameEn: name,
      nameAr: name,
      category: MarketCategory.agriculture,
      unitLabel: 'USD/t',
      currency: 'USD',
      priceUsd: price,
      previousUsd: previous,
      period: period,
      monthly: monthly,
      source: source,
      updatedAt: DateTime(2026, 10, 26),
      quality:
          price == null ? PriceQuality.unavailable : PriceQuality.indicative,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a month\'s average says so; the rest wait on one card',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        commodityQuotesProvider(MarketCategory.agriculture)
            .overrideWith((Ref ref) async => <CommodityQuote>[
                  _q('WHEAT', 'Wheat',
                      price: 246.85,
                      previous: 237.86,
                      period: '2026-09',
                      monthly: true),
                  _q('HRC', 'Steel HRC'),
                  _q('REBAR', 'Steel Rebar'),
                ]),
        fxSnapshotProvider.overrideWith((Ref ref) async => FxSnapshot(
            ratesPerUsd: const <String, double>{},
            updatedAt: DateTime(2026),
            source: 'test')),
      ],
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
        home: const Scaffold(
          body: SingleChildScrollView(
            child:
                CommodityCategorySection(category: MarketCategory.agriculture),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.textContaining(l.marketMonthlyAvg('September 2026')),
        findsOneWidget);
    expect(find.textContaining('+3.8%'), findsOneWidget);
    expect(find.text(l.marketUnavailable), findsOneWidget); // one card for both
    expect(find.text('Steel HRC · HRC'), findsOneWidget);
  });
}
