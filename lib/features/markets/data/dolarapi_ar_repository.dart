import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Argentina parallel ("blue") USD market from dolarapi.com (keyless, CORS).
///
/// Response: `{ compra: <buy>, venta: <sell>, fechaActualizacion: "ISO" }`.
/// Only the USD blue rate is exposed reliably; other pairs stay unavailable.
class DolarApiArRepository implements ParallelMarketRepository {
  DolarApiArRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  @override
  String get id => 'dolarapi_ar';
  @override
  String get source => 'dolarapi.com (blue)';

  static const String _cacheKey = 'par_ar';
  static const Duration _ttl = Duration(minutes: 30);
  static final Uri _url = Uri.parse('https://dolarapi.com/v1/dolares/blue');

  @override
  Future<List<FxQuote>> quotes(CountryMarket market) async {
    Map<String, dynamic>? data;
    final dynamic cached = await _cache.read(_cacheKey, maxAge: _ttl);
    if (cached is Map) data = Map<String, dynamic>.from(cached);

    if (data == null) {
      try {
        final dynamic fetched = await _http.getJson(_url);
        if (fetched is Map) {
          data = Map<String, dynamic>.from(fetched);
          await _cache.write(_cacheKey, data);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(_cacheKey);
        if (stale is Map) {
          data = Map<String, dynamic>.from(stale);
        } else {
          return const <FxQuote>[]; // unavailable — never fabricate
        }
      }
    }

    return parse(data ?? <String, dynamic>{}, market, source);
  }

  /// Pure parser (unit-tested).
  static List<FxQuote> parse(
    Map<String, dynamic> data,
    CountryMarket market,
    String source,
  ) {
    final double? buy = asDoubleOrNull(data['compra']);
    final double? sell = asDoubleOrNull(data['venta']);
    if (buy == null && sell == null) return const <FxQuote>[];
    DateTime updated = DateTime.now();
    final dynamic f = data['fechaActualizacion'];
    if (f is String) {
      final DateTime? p = DateTime.tryParse(f);
      if (p != null) updated = p;
    }
    return <FxQuote>[
      FxQuote(
        currency: 'USD',
        baseCurrency: market.base,
        country: market.country,
        marketType: MarketType.parallel,
        buy: buy,
        sell: sell,
        source: source,
        updatedAt: updated,
      ),
    ];
  }
}
