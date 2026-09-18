import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart' show asDoubleOrNull;

/// Precious-metals spot from gold-api.com (keyless, USD per troy ounce).
///
/// Response: `{ name, price, symbol, updatedAt }`. Prices are indicative /
/// delayed and labelled as such; on failure a metal is marked unavailable
/// rather than fabricated.
class GoldApiMetalsRepository implements MarketDataProvider {
  GoldApiMetalsRepository({MarketHttp? http, RateCache? cache})
      : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  final MarketHttp _http;
  final RateCache _cache;

  @override
  MarketCategory get category => MarketCategory.preciousMetals;

  static const Duration _ttl = Duration(minutes: 15);

  @override
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs) async {
    final List<CommodityQuote> out = <CommodityQuote>[];
    for (final CommoditySpec spec in specs) {
      out.add(await _one(spec));
    }
    return out;
  }

  Future<CommodityQuote> _one(CommoditySpec spec) async {
    final String sym = spec.apiSymbol ?? spec.code;
    final String key = 'metal_$sym';
    Map<String, dynamic>? data;

    final dynamic cached = await _cache.read(key, maxAge: _ttl);
    if (cached is Map) data = Map<String, dynamic>.from(cached);

    if (data == null) {
      try {
        final dynamic fetched =
            await _http.getJson(Uri.parse('https://api.gold-api.com/price/$sym'));
        if (fetched is Map) {
          data = Map<String, dynamic>.from(fetched);
          await _cache.write(key, data);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(key);
        if (stale is Map) data = Map<String, dynamic>.from(stale);
      }
    }

    return parse(spec, data);
  }

  /// Pure parser (unit-tested).
  static CommodityQuote parse(CommoditySpec spec, Map<String, dynamic>? data) {
    final double? price = data == null ? null : asDoubleOrNull(data['price']);
    if (price == null) return _unavailable(spec);
    DateTime updated = DateTime.now();
    final dynamic u = data!['updatedAt'];
    if (u is String) {
      final DateTime? p = DateTime.tryParse(u);
      if (p != null) updated = p;
    }
    return CommodityQuote(
      code: spec.code,
      nameEn: spec.nameEn,
      nameAr: spec.nameAr,
      category: spec.category,
      unitLabel: spec.unitLabel,
      currency: 'USD',
      priceUsd: price,
      source: 'gold-api.com',
      updatedAt: updated,
      quality: PriceQuality.delayed,
    );
  }

  static CommodityQuote _unavailable(CommoditySpec spec) => CommodityQuote(
        code: spec.code,
        nameEn: spec.nameEn,
        nameAr: spec.nameAr,
        category: spec.category,
        unitLabel: spec.unitLabel,
        currency: 'USD',
        source: 'gold-api.com',
        updatedAt: DateTime.now(),
        quality: PriceQuality.unavailable,
      );
}
