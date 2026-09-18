import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Official mid-market FX rates from open.er-api.com (keyless, CORS-enabled).
///
/// Response: `{ result:"success", rates:{DZD:.., EUR:..}, time_last_update_unix, provider }`.
class OpenErApiFxRepository implements FxRatesRepository {
  OpenErApiFxRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  static const String _cacheKey = 'fx_usd';
  static const Duration _ttl = Duration(hours: 1);
  static final Uri _url = Uri.parse('https://open.er-api.com/v6/latest/USD');

  @override
  Future<FxSnapshot> latestVsUsd() async {
    final dynamic cached = await _cache.read(_cacheKey, maxAge: _ttl);
    if (cached is Map) return FxSnapshot.fromErApi(Map<String, dynamic>.from(cached));

    try {
      final dynamic data = await _http.getJson(_url);
      if (data is Map && data['result'] == 'success') {
        final Map<String, dynamic> map = Map<String, dynamic>.from(data);
        await _cache.write(_cacheKey, map);
        return FxSnapshot.fromErApi(map);
      }
      throw MarketFetchException('unexpected FX payload');
    } catch (_) {
      final dynamic stale = await _cache.readStale(_cacheKey);
      if (stale is Map) return FxSnapshot.fromErApi(Map<String, dynamic>.from(stale));
      rethrow;
    }
  }
}
