import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Parallel-market quotes for ANY country via the owner's parallel proxy
/// (a Supabase Edge Function or similar). The OWNER picks the data source for
/// each country server-side; the proxy URL is non-secret and injected at build
/// time (AppEnv.parallelApiUrl). Dormant until configured — every country then
/// reads "unavailable" (and manual entry still works), never a fabricated rate.
///
/// Contract:  GET <url>?country=<iso2>
///   -> { "country": "...", "quotes": [ { currency, base?, buy?, sell?,
///        source?, updatedAt? } ] }
/// A pair with neither buy nor sell is dropped (never invented).
class BackendParallelRepository implements ParallelMarketRepository {
  BackendParallelRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  @override
  String get id => 'backend';
  @override
  String get source => 'parallel proxy';

  static const Duration _ttl = Duration(minutes: 30);

  @override
  Future<List<FxQuote>> quotes(CountryMarket market) async {
    if (!AppEnv.hasParallelApi) return const <FxQuote>[];
    final String cacheKey = 'par_be_${market.country}';

    Map<String, dynamic>? data;
    final dynamic cached = await _cache.read(cacheKey, maxAge: _ttl);
    if (cached is Map) data = Map<String, dynamic>.from(cached);

    if (data == null) {
      try {
        final Uri url = Uri.parse(AppEnv.parallelApiUrl).replace(
          queryParameters: <String, String>{'country': market.country},
        );
        final dynamic fetched = await _http.getJson(url);
        if (fetched is Map) {
          data = Map<String, dynamic>.from(fetched);
          await _cache.write(cacheKey, data);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(cacheKey);
        if (stale is Map) {
          data = Map<String, dynamic>.from(stale);
        } else {
          return const <FxQuote>[]; // unavailable — never fabricate
        }
      }
    }

    return parse(data ?? const <String, dynamic>{}, market);
  }

  /// Pure parser (unit-testable): normalizes the proxy payload into quotes.
  static List<FxQuote> parse(Map<String, dynamic> data, CountryMarket market) {
    final Object? quotes = data['quotes'];
    if (quotes is! List) return const <FxQuote>[];
    final List<FxQuote> out = <FxQuote>[];
    for (final Object? item in quotes) {
      if (item is! Map) continue;
      final Map<String, dynamic> m = item.cast<String, dynamic>();
      final Object? currency = m['currency'];
      if (currency is! String) continue;
      final double? buy = asDoubleOrNull(m['buy']);
      final double? sell = asDoubleOrNull(m['sell']);
      if (buy == null && sell == null) continue; // never fabricate
      DateTime updated = DateTime.now();
      final Object? f = m['updatedAt'];
      if (f is String) {
        final DateTime? p = DateTime.tryParse(f);
        if (p != null) updated = p;
      }
      out.add(FxQuote(
        currency: currency,
        baseCurrency: (m['base'] as String?) ?? market.base,
        country: market.country,
        marketType: MarketType.parallel,
        buy: buy,
        sell: sell,
        source: (m['source'] as String?) ?? 'parallel proxy',
        updatedAt: updated,
      ));
    }
    return out;
  }
}
