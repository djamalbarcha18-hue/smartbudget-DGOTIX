import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/data/owner_parallel_repository.dart';
import 'package:smartbudget/features/markets/data/owner_rates_service.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/presentation/owner_rates_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

final CountryMarket _dz = MarketConfig.countries
    .firstWhere((CountryMarket c) => c.country == 'dz');

/// The server, in memory: what is stored and every write asked of it.
class _FakeService implements OwnerRatesService {
  _FakeService({List<Map<String, dynamic>>? rows, this.failWrites = false})
      : rows = rows ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> rows;
  final bool failWrites;
  final List<String> writes = <String>[];

  @override
  Future<List<dynamic>> fetch(String country) async => rows;

  @override
  Future<bool> isAdmin() async => true;

  @override
  Future<void> setRate(String country, String currency,
      {double? buy, double? sell}) async {
    if (failWrites) throw Exception('offline');
    writes.add('$country $currency $buy $sell');
  }
}

Future<_FakeService> _pump(WidgetTester tester, _FakeService service) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      ownerRatesServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[DsColors.light, DsGlass.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OwnerRatesPage(country: _dz),
    ),
  ));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('Algeria reads the owner-entered rates, with the Square currencies', () {
    expect(_dz.parallelSourceId, OwnerParallelRepository.sourceId);
    expect(_dz.pairs, containsAll(<String>['EUR', 'USD', 'GBP', 'CAD']));
  });

  group('parse', () {
    test('keeps buy, sell and the time the rate was set', () {
      final List<FxQuote> qs = OwnerParallelRepository.parse(<dynamic>[
        <String, dynamic>{
          'currency': 'EUR',
          'buy': 274.5,
          'sell': '276.50',
          'updated_at': '2026-11-10T09:30:00Z',
        },
      ], _dz, 'SmartBudget');
      expect(qs, hasLength(1));
      expect(qs.single.buy, 274.5);
      expect(qs.single.sell, 276.5);
      expect(qs.single.baseCurrency, 'DZD');
      expect(qs.single.marketType, MarketType.parallel);
      expect(qs.single.updatedAt.toUtc(), DateTime.utc(2026, 11, 10, 9, 30));
    });

    test('one side alone is kept; nothing, zero or junk is dropped', () {
      final List<FxQuote> qs = OwnerParallelRepository.parse(<dynamic>[
        <String, dynamic>{'currency': 'USD', 'buy': null, 'sell': 245},
        <String, dynamic>{'currency': 'GBP', 'buy': null, 'sell': null},
        <String, dynamic>{'currency': 'CAD', 'buy': 0, 'sell': -3},
        <String, dynamic>{'buy': 1, 'sell': 2},
        'junk',
      ], _dz, 'SmartBudget');
      expect(qs.map((FxQuote q) => q.currency), <String>['USD']);
      expect(qs.single.buy, isNull);
      expect(qs.single.sell, 245);
    });
  });

  group('repository', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('server unreachable and nothing seen before: unavailable', () async {
      final OwnerParallelRepository repo = OwnerParallelRepository(
          fetch: (String _) async => throw Exception('offline'));
      expect(await repo.quotes(_dz), isEmpty);
    });

    test('server unreachable later: the last figures seen are shown', () async {
      bool online = true;
      int calls = 0;
      final OwnerParallelRepository repo =
          OwnerParallelRepository(fetch: (String _) async {
        calls++;
        if (!online) throw Exception('offline');
        return <dynamic>[
          <String, dynamic>{'currency': 'EUR', 'buy': 274.5, 'sell': 276.5},
        ];
      });
      expect((await repo.quotes(_dz)).single.buy, 274.5);
      // Within the cache window the server is not asked again.
      expect((await repo.quotes(_dz)).single.buy, 274.5);
      expect(calls, 1);
      online = false;
      expect((await repo.quotes(_dz)).single.sell, 276.5);
    });

    test('nothing entered yet: unavailable, not an error', () async {
      final OwnerParallelRepository repo =
          OwnerParallelRepository(fetch: (String _) async => <dynamic>[]);
      expect(await repo.quotes(_dz), isEmpty);
    });
  });

  group('the owner page', () {
    testWidgets('opens with what the server holds', (WidgetTester tester) async {
      await _pump(
          tester,
          _FakeService(rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'currency': 'EUR',
              'buy': 274.5,
              'sell': 276.5,
              'updated_at': '2026-11-10T09:30:00Z',
            },
          ]));
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey<String>('buy-EUR')))
              .controller!
              .text,
          '274.50');
      expect(find.textContaining('Last set:'), findsOneWidget);
    });

    testWidgets('saves only what changed', (WidgetTester tester) async {
      final _FakeService s = await _pump(
          tester,
          _FakeService(rows: <Map<String, dynamic>>[
            <String, dynamic>{'currency': 'EUR', 'buy': 274.5, 'sell': 276.5},
            <String, dynamic>{'currency': 'USD', 'buy': 242, 'sell': 245},
          ]));
      await tester.enterText(
          find.byKey(const ValueKey<String>('buy-EUR')), '275');
      await tester.enterText(
          find.byKey(const ValueKey<String>('sell-CAD')), '172,5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(s.writes,
          <String>['dz EUR 275.0 276.5', 'dz CAD null 172.5']);
      expect(find.text('Rates saved'), findsOneWidget);
    });

    testWidgets('emptying both fields removes the currency',
        (WidgetTester tester) async {
      final _FakeService s = await _pump(
          tester,
          _FakeService(rows: <Map<String, dynamic>>[
            <String, dynamic>{'currency': 'USD', 'buy': 242, 'sell': 245},
          ]));
      await tester.enterText(find.byKey(const ValueKey<String>('buy-USD')), '');
      await tester.enterText(
          find.byKey(const ValueKey<String>('sell-USD')), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(s.writes, <String>['dz USD null null']);
    });

    testWidgets('a bad figure is refused and nothing is sent',
        (WidgetTester tester) async {
      final _FakeService s = await _pump(tester, _FakeService());
      await tester.enterText(
          find.byKey(const ValueKey<String>('buy-EUR')), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(s.writes, isEmpty);
      expect(find.text('Enter a number above zero'), findsWidgets);
    });

    testWidgets('a failed save says so', (WidgetTester tester) async {
      await _pump(tester, _FakeService(failWrites: true));
      await tester.enterText(
          find.byKey(const ValueKey<String>('buy-EUR')), '275');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
    });
  });
}
