import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';

/// Official mid-market FX rates (units per USD). Backed by a keyless public API
/// on the client, or a backend proxy later — the interface stays the same.
abstract interface class FxRatesRepository {
  Future<FxSnapshot> latestVsUsd();
}

/// Crypto spot prices (global USD + the user's local currency when supported).
abstract interface class CryptoRepository {
  Future<List<CryptoQuote>> quotes(List<CryptoAsset> assets, String localCode);
}

/// A parallel-market source for ONE country. Implementations return real
/// buy/sell quotes; when a source is unavailable it is simply not registered,
/// and the app renders "unavailable" rather than inventing a rate.
abstract interface class ParallelMarketRepository {
  String get id;
  String get source;

  /// Parallel quotes for [market], keyed per configured pair. May return fewer
  /// entries than requested when only some pairs are covered.
  Future<List<FxQuote>> quotes(CountryMarket market);
}
