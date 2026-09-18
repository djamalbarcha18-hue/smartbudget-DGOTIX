import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart' show asDoubleOrNull;

/// Fetches a commodity category from the OWNER's market proxy (a Supabase Edge
/// Function or similar). The proxy holds provider keys server-side and decides
/// which data provider to use — nothing secret ships in the client.
///
/// Contract: `GET {baseUrl}?category=<enum name>` →
///   { "quotes": [ { code, priceUsd?, previousUsd?, unit?, benchmark?, region?,
///                   source, updatedAt, quality } ] }
/// Any code the proxy omits (or returns without a price) renders "unavailable".
class BackendMarketProvider implements MarketDataProvider {
  BackendMarketProvider(
    this.category,
    this.baseUrl, {
    MarketHttp? http,
    RateCache? cache,
  })  : _http = http ?? const MarketHttp(),
        _cache = cache ?? const RateCache();

  @override
  final MarketCategory category;
  final String baseUrl;
  final MarketHttp _http;
  final RateCache _cache;

  static const Duration _ttl = Duration(minutes: 15);

  @override
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs) async {
    final String key = 'backend_${category.name}';
    dynamic data;

    final dynamic cached = await _cache.read(key, maxAge: _ttl);
    if (cached is Map) data = cached;

    if (data == null) {
      try {
        final Uri url = Uri.parse('$baseUrl?category=${category.name}');
        final dynamic fetched = await _http.getJson(url);
        if (fetched is Map) {
          data = fetched;
          await _cache.write(key, fetched);
        }
      } catch (_) {
        final dynamic stale = await _cache.readStale(key);
        if (stale is Map) data = stale;
      }
    }

    return parse(specs, data is Map ? Map<String, dynamic>.from(data) : null);
  }

  /// Pure parser (unit-tested). Maps proxy rows onto the configured specs so
  /// names/units stay consistent; missing rows become unavailable quotes.
  static List<CommodityQuote> parse(
      List<CommoditySpec> specs, Map<String, dynamic>? data) {
    final Map<String, Map<String, dynamic>> byCode =
        <String, Map<String, dynamic>>{};
    final Object? rows = data?['quotes'];
    if (rows is List) {
      for (final Object? r in rows) {
        if (r is Map && r['code'] is String) {
          byCode[r['code'] as String] = Map<String, dynamic>.from(r);
        }
      }
    }

    final DateTime now = DateTime.now();
    return specs.map((CommoditySpec spec) {
      final Map<String, dynamic>? r = byCode[spec.code];
      final double? price = r == null ? null : asDoubleOrNull(r['priceUsd']);
      if (price == null) {
        return CommodityQuote(
          code: spec.code,
          nameEn: spec.nameEn,
          nameAr: spec.nameAr,
          category: spec.category,
          unitLabel: spec.unitLabel,
          currency: spec.currency,
          benchmark: spec.benchmark,
          region: spec.region,
          source: spec.benchmark ?? 'requires data source',
          updatedAt: now,
          quality: PriceQuality.unavailable,
        );
      }
      DateTime updated = now;
      final Object? u = r!['updatedAt'];
      if (u is String) {
        final DateTime? p = DateTime.tryParse(u);
        if (p != null) updated = p;
      }
      return CommodityQuote(
        code: spec.code,
        nameEn: spec.nameEn,
        nameAr: spec.nameAr,
        category: spec.category,
        unitLabel: (r['unit'] as String?) ?? spec.unitLabel,
        currency: spec.currency,
        priceUsd: price,
        previousUsd: asDoubleOrNull(r['previousUsd']),
        benchmark: (r['benchmark'] as String?) ?? spec.benchmark,
        region: (r['region'] as String?) ?? spec.region,
        source: (r['source'] as String?) ?? 'proxy',
        updatedAt: updated,
        quality: _quality(r['quality']),
      );
    }).toList();
  }

  static PriceQuality _quality(Object? v) => switch (v) {
        'realtime' => PriceQuality.realtime,
        'nearRealtime' => PriceQuality.nearRealtime,
        'indicative' => PriceQuality.indicative,
        'unavailable' => PriceQuality.unavailable,
        _ => PriceQuality.delayed,
      };
}
