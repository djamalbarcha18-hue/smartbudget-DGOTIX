import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Crypto spot prices from CoinGecko's public (keyless) simple/price endpoint.
///
/// Response: `{ bitcoin:{usd:.., dzd:.., last_updated_at:..}, ... }`.
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
    final String local = localCode.toLowerCase();
    final String vs = local == 'usd' ? 'usd' : 'usd,$local';
    final String ids = assets.map((CryptoAsset a) => a.coingeckoId).join(',');
    final String key = 'crypto_$local';
    final Uri url = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=$vs&include_last_updated_at=true');

    Map<String, dynamic>? data;
    final dynamic cached = await _cache.read(key, maxAge: _ttl);
    if (cached is Map) data = Map<String, dynamic>.from(cached);

    if (data == null) {
      try {
        final dynamic fetched = await _http.getJson(url);
        if (fetched is Map) {
          data = Map<String, dynamic>.from(fetched);
          await _cache.write(key, data);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(key);
        if (stale is Map) {
          data = Map<String, dynamic>.from(stale);
        } else {
          rethrow;
        }
      }
    }

    return parse(data ?? <String, dynamic>{}, assets, localCode);
  }

  /// Pure parser (unit-tested with sample payloads).
  static List<CryptoQuote> parse(
    Map<String, dynamic> data,
    List<CryptoAsset> assets,
    String localCode,
  ) {
    final DateTime now = DateTime.now();
    final String local = localCode.toLowerCase();
    return assets.map((CryptoAsset a) {
      final dynamic m = data[a.coingeckoId];
      double? usd;
      double? localVal;
      DateTime updated = now;
      if (m is Map) {
        usd = asDoubleOrNull(m['usd']);
        localVal = local == 'usd' ? usd : asDoubleOrNull(m[local]);
        final dynamic lu = m['last_updated_at'];
        if (lu is num) {
          updated = DateTime.fromMillisecondsSinceEpoch(lu.toInt() * 1000,
              isUtc: true);
        }
      }
      return CryptoQuote(
        symbol: a.symbol,
        name: a.name,
        usd: usd,
        local: localVal,
        localCode: localCode,
        source: 'CoinGecko',
        updatedAt: updated,
      );
    }).toList();
  }
}
