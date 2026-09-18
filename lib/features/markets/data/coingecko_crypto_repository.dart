import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Crypto market data from CoinGecko's public (keyless) `/coins/markets`
/// endpoint — one call returns price, 24h/7d change and a 7-day sparkline.
///
/// Response: `[ { id, current_price, price_change_percentage_24h,
///   price_change_percentage_7d_in_currency, sparkline_in_7d:{price:[]},
///   last_updated }, … ]` (priced in USD). Local currency is derived in the UI
/// from the FX snapshot, keeping one source of truth for conversion.
class CoinGeckoCryptoRepository implements CryptoRepository {
  CoinGeckoCryptoRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  static const Duration _ttl = Duration(minutes: 10);

  @override
  Future<List<CryptoQuote>> quotes(
      List<CryptoAsset> assets, String localCode) async {
    final String ids = assets.map((CryptoAsset a) => a.coingeckoId).join(',');
    const String key = 'crypto_markets';
    final Uri url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=$ids'
        '&order=market_cap_desc&sparkline=true&price_change_percentage=24h,7d');

    List<dynamic>? data;
    final dynamic cached = await _cache.read(key, maxAge: _ttl);
    if (cached is List) data = cached;

    if (data == null) {
      try {
        final dynamic fetched = await _http.getJson(url);
        if (fetched is List) {
          data = fetched;
          await _cache.write(key, data);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(key);
        if (stale is List) {
          data = stale;
        } else {
          rethrow;
        }
      }
    }

    return parse(data ?? const <dynamic>[], assets, localCode);
  }

  /// Pure parser (unit-tested).
  static List<CryptoQuote> parse(
    List<dynamic> data,
    List<CryptoAsset> assets,
    String localCode,
  ) {
    final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{};
    for (final dynamic row in data) {
      if (row is Map && row['id'] is String) {
        byId[row['id'] as String] = Map<String, dynamic>.from(row);
      }
    }

    final DateTime now = DateTime.now();
    return assets.map((CryptoAsset a) {
      final Map<String, dynamic>? m = byId[a.coingeckoId];
      double? usd;
      double? change24h;
      double? change7d;
      List<double>? spark;
      DateTime updated = now;
      if (m != null) {
        usd = asDoubleOrNull(m['current_price']);
        change24h = asDoubleOrNull(m['price_change_percentage_24h']);
        change7d = asDoubleOrNull(m['price_change_percentage_7d_in_currency']);
        final dynamic s = m['sparkline_in_7d'];
        if (s is Map && s['price'] is List) {
          spark = <double>[
            for (final dynamic p in s['price'] as List)
              if (asDoubleOrNull(p) != null) asDoubleOrNull(p)!,
          ];
        }
        final dynamic lu = m['last_updated'];
        if (lu is String) {
          final DateTime? p = DateTime.tryParse(lu);
          if (p != null) updated = p;
        }
      }
      return CryptoQuote(
        symbol: a.symbol,
        name: a.name,
        usd: usd,
        localCode: localCode,
        change24h: change24h,
        change7d: change7d,
        sparkline: spark,
        source: 'CoinGecko',
        updatedAt: updated,
      );
    }).toList();
  }
}
