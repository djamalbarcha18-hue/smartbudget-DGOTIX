import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

/// Algeria parallel ("Square Port-Saïd") rates from squarealgerie.com — a
/// keyless, CORS-enabled community API (unofficial). Buy/sell per currency.
///
/// Expected shape (tolerant): `{ "currencies": [ { "code":"EUR",
/// "buy":274.6, "sell":276.6 }, ... ] }`. Anything missing both buy and sell is
/// dropped — the app shows "unavailable" rather than a fabricated rate.
class SquareDzRepository implements ParallelMarketRepository {
  SquareDzRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  @override
  String get id => 'square_dz';
  @override
  String get source => 'squarealgerie.com (Square Port-Saïd)';

  static const String _cacheKey = 'par_dz_square';
  static const Duration _ttl = Duration(minutes: 30);
  static final Uri _url = Uri.parse('https://squarealgerie.com/api/rates');

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

    return parse(data ?? const <String, dynamic>{}, market, source);
  }

  /// Pure, tolerant parser (unit-testable): finds a list of currency entries
  /// wherever the payload keeps it, and reads buy/sell under common aliases.
  static List<FxQuote> parse(
    Map<String, dynamic> data,
    CountryMarket market,
    String source,
  ) {
    final List<dynamic>? list = _findCurrencyList(data);
    if (list == null) return const <FxQuote>[];
    final DateTime updated = _readUpdated(data);
    final List<FxQuote> out = <FxQuote>[];
    for (final dynamic item in list) {
      if (item is! Map) continue;
      final Map<String, dynamic> m = item.cast<String, dynamic>();
      final Object? code = m['code'] ?? m['currency'] ?? m['symbol'];
      if (code is! String) continue;
      final double? buy =
          asDoubleOrNull(m['buy'] ?? m['achat'] ?? m['bid'] ?? m['buy_rate']);
      final double? sell =
          asDoubleOrNull(m['sell'] ?? m['vente'] ?? m['ask'] ?? m['sell_rate']);
      if (buy == null && sell == null) continue;
      out.add(FxQuote(
        currency: code.toUpperCase(),
        baseCurrency: market.base,
        country: market.country,
        marketType: MarketType.parallel,
        buy: buy,
        sell: sell,
        source: source,
        updatedAt: updated,
      ));
    }
    return out;
  }

  static List<dynamic>? _findCurrencyList(Map<String, dynamic> data) {
    for (final Object? v in <Object?>[
      data['currencies'],
      data['rates'],
      data['parallel'],
      data['data'],
      (data['rates'] is Map)
          ? (data['rates'] as Map)['currencies']
          : null,
    ]) {
      if (v is List) return v;
    }
    return null;
  }

  static DateTime _readUpdated(Map<String, dynamic> data) {
    for (final Object? v in <Object?>[
      data['updatedAt'],
      data['updated_at'],
      data['date'],
      data['timestamp'],
    ]) {
      if (v is String) {
        final DateTime? p = DateTime.tryParse(v);
        if (p != null) return p;
      }
    }
    return DateTime.now();
  }
}
