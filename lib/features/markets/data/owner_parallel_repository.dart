import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Parallel-market rates typed in by the app's owner (Settings > Parallel
/// rates, admins only) and read by everyone. A country's street rate has no
/// official feed and the community sites that publish one come and go, so the
/// figure is kept on our own server, with the time it was last set.
///
/// Nothing stored, or the server unreachable with nothing seen before: the
/// country reads "unavailable" and the user's own manual entry still works.
class OwnerParallelRepository implements ParallelMarketRepository {
  OwnerParallelRepository({required this.fetch, RateCache? cache})
      : _cache = cache ?? const RateCache();

  /// The stored rows of a country (see OwnerRatesService.fetch).
  final Future<List<dynamic>> Function(String country) fetch;
  final RateCache _cache;

  static const String sourceId = 'owner';

  @override
  String get id => sourceId;
  @override
  String get source => 'SmartBudget';

  static const Duration _ttl = Duration(minutes: 30);

  static String cacheKey(String country) => 'par_owner_$country';

  @override
  Future<List<FxQuote>> quotes(CountryMarket market) async {
    final String key = cacheKey(market.country);
    List<dynamic>? rows;
    final dynamic cached = await _cache.read(key, maxAge: _ttl);
    if (cached is List) rows = cached;

    if (rows == null) {
      try {
        rows = await fetch(market.country);
        await _cache.write(key, rows);
      } catch (_) {
        final dynamic stale = await _cache.readStale(key);
        if (stale is List) {
          rows = stale;
        } else {
          return const <FxQuote>[]; // unavailable, never invented
        }
      }
    }
    return parse(rows, market, source);
  }

  /// Pure parser (unit-testable). A row with neither side is dropped.
  static List<FxQuote> parse(
      List<dynamic> rows, CountryMarket market, String source) {
    final List<FxQuote> out = <FxQuote>[];
    for (final dynamic item in rows) {
      if (item is! Map) continue;
      final Map<String, dynamic> m = item.cast<String, dynamic>();
      final Object? currency = m['currency'];
      if (currency is! String || currency.isEmpty) continue;
      final double? buy = _positive(asDoubleOrNull(m['buy']));
      final double? sell = _positive(asDoubleOrNull(m['sell']));
      if (buy == null && sell == null) continue;
      final Object? at = m['updated_at'];
      out.add(FxQuote(
        currency: currency.toUpperCase(),
        baseCurrency: market.base,
        country: market.country,
        marketType: MarketType.parallel,
        buy: buy,
        sell: sell,
        source: source,
        updatedAt:
            (at is String ? DateTime.tryParse(at) : null) ?? AppClock.now(),
      ));
    }
    return out;
  }

  static double? _positive(double? v) =>
      v != null && v.isFinite && v > 0 ? v : null;
}
