import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/markets/data/coingecko_crypto_repository.dart';
import 'package:smartbudget/features/markets/data/dolarapi_ar_repository.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';

void main() {
  group('FxSnapshot.fromErApi', () {
    final FxSnapshot snap = FxSnapshot.fromErApi(<String, dynamic>{
      'result': 'success',
      'provider': 'open.er-api.com',
      'time_last_update_unix': 1700000000,
      'rates': <String, dynamic>{'USD': 1, 'DZD': 134.5, 'EUR': 0.92},
    });

    test('parses rates and timestamp', () {
      expect(snap.ratesPerUsd['DZD'], 134.5);
      expect(snap.updatedAt.toUtc(),
          DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true));
    });

    test('cross rate: base units per 1 currency', () {
      // USD/DZD official = DZD per 1 USD = 134.5
      expect(snap.cross('USD', 'DZD'), 134.5);
      // EUR/DZD = rate[DZD]/rate[EUR]
      expect(snap.cross('EUR', 'DZD'), closeTo(134.5 / 0.92, 1e-9));
    });

    test('missing leg yields null (never fabricated)', () {
      expect(snap.cross('GBP', 'DZD'), isNull);
    });
  });

  group('CoinGecko parse', () {
    const List<CryptoAsset> assets = <CryptoAsset>[
      CryptoAsset(symbol: 'BTC', name: 'Bitcoin', coingeckoId: 'bitcoin'),
      CryptoAsset(symbol: 'SOL', name: 'Solana', coingeckoId: 'solana'),
    ];

    test('maps usd + local price', () {
      final List<CryptoQuote> q = CoinGeckoCryptoRepository.parse(
        <String, dynamic>{
          'bitcoin': <String, dynamic>{
            'usd': 65000,
            'dzd': 8742500,
            'last_updated_at': 1700000000,
          },
        },
        assets,
        'DZD',
      );
      expect(q.first.symbol, 'BTC');
      expect(q.first.usd, 65000);
      expect(q.first.local, 8742500);
      // Missing asset -> usd null (shown as unavailable, not zero).
      expect(q[1].usd, isNull);
    });

    test('local equals usd when base is USD', () {
      final List<CryptoQuote> q = CoinGeckoCryptoRepository.parse(
        <String, dynamic>{
          'bitcoin': <String, dynamic>{'usd': 65000},
        },
        assets,
        'USD',
      );
      expect(q.first.local, 65000);
    });
  });

  group('DolarApi (Argentina blue) parse', () {
    const CountryMarket ar = CountryMarket(
      country: 'ar',
      nameEn: 'Argentina',
      nameAr: 'الأرجنتين',
      base: 'ARS',
      pairs: <String>['USD', 'EUR'],
      parallelSourceId: 'dolarapi_ar',
    );

    test('parses buy/sell as a parallel USD quote', () {
      final List<FxQuote> q = DolarApiArRepository.parse(
        <String, dynamic>{
          'compra': 1000.0,
          'venta': 1020.0,
          'fechaActualizacion': '2026-01-01T12:00:00.000Z',
        },
        ar,
        'dolarapi.com (blue)',
      );
      expect(q.single.currency, 'USD');
      expect(q.single.baseCurrency, 'ARS');
      expect(q.single.marketType, MarketType.parallel);
      expect(q.single.buy, 1000.0);
      expect(q.single.sell, 1020.0);
    });

    test('empty payload yields no quotes (unavailable)', () {
      expect(DolarApiArRepository.parse(<String, dynamic>{}, ar, 's'), isEmpty);
    });
  });
}
