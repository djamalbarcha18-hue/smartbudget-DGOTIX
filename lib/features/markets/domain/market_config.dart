import 'package:flutter/foundation.dart';

/// A configured crypto asset (configuration, NOT price data).
@immutable
class CryptoAsset {
  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.coingeckoId,
  });
  final String symbol; // BTC
  final String name; // Bitcoin
  final String coingeckoId; // bitcoin
}

/// A configured country market.
///
/// [parallelSourceId] names the parallel-market data provider (see the parallel
/// registry). `null` means there is no reliable free source yet — the UI shows
/// "unavailable" for the parallel market, never a fabricated number.
@immutable
class CountryMarket {
  const CountryMarket({
    required this.country,
    required this.nameEn,
    required this.nameAr,
    required this.base,
    required this.pairs,
    this.parallelSourceId,
  });
  final String country; // ISO alpha-2, e.g. 'dz'
  final String nameEn;
  final String nameAr;
  final String base; // base currency code, e.g. 'DZD'
  final List<String> pairs; // quoted currencies, e.g. ['USD','EUR']
  final String? parallelSourceId;
}

/// Static configuration for the Markets feature. Adding a country, pair, crypto
/// or parallel source is a data-only edit here — no code rewrite needed.
abstract final class MarketConfig {
  /// Official mid-market FX source covers every fiat via USD cross-rates.
  static const List<CryptoAsset> crypto = <CryptoAsset>[
    CryptoAsset(symbol: 'BTC', name: 'Bitcoin', coingeckoId: 'bitcoin'),
    CryptoAsset(symbol: 'ETH', name: 'Ethereum', coingeckoId: 'ethereum'),
    CryptoAsset(symbol: 'USDT', name: 'Tether', coingeckoId: 'tether'),
    CryptoAsset(symbol: 'USDC', name: 'USD Coin', coingeckoId: 'usd-coin'),
    CryptoAsset(symbol: 'BNB', name: 'BNB', coingeckoId: 'binancecoin'),
    CryptoAsset(symbol: 'SOL', name: 'Solana', coingeckoId: 'solana'),
  ];

  static const List<CountryMarket> countries = <CountryMarket>[
    CountryMarket(
      country: 'dz',
      nameEn: 'Algeria',
      nameAr: 'الجزائر',
      base: 'DZD',
      pairs: <String>['USD', 'EUR', 'GBP', 'SAR', 'AED'],
      // Live Square Port-Saïd rates via a keyless, CORS-enabled community API
      // (unofficial). Falls back to "unavailable" if the source is down; manual
      // entry always remains available.
      parallelSourceId: 'square_dz',
    ),
    CountryMarket(
      country: 'ar',
      nameEn: 'Argentina',
      nameAr: 'الأرجنتين',
      base: 'ARS',
      pairs: <String>['USD', 'EUR'],
      // Real parallel ("blue") data via a keyless public API.
      parallelSourceId: 'dolarapi_ar',
    ),
    CountryMarket(
      country: 'lb',
      nameEn: 'Lebanon',
      nameAr: 'لبنان',
      base: 'LBP',
      pairs: <String>['USD'],
      parallelSourceId: 'backend',
    ),
    CountryMarket(
      country: 'ng',
      nameEn: 'Nigeria',
      nameAr: 'نيجيريا',
      base: 'NGN',
      pairs: <String>['USD', 'EUR', 'GBP'],
      parallelSourceId: 'backend',
    ),
  ];
}
