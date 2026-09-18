import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/markets/data/backend_market_provider.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';

void main() {
  final List<CommoditySpec> specs =
      CommodityConfig.byCategory(MarketCategory.industrialMetals);

  test('maps proxy rows onto specs; fills live fields', () {
    final List<CommodityQuote> q = BackendMarketProvider.parse(specs, <String, dynamic>{
      'quotes': <dynamic>[
        <String, dynamic>{
          'code': 'XCU',
          'priceUsd': 9500.0,
          'unit': 'USD/t',
          'source': 'MetalpriceAPI',
          'updatedAt': '2026-01-01T00:00:00Z',
          'quality': 'delayed',
        },
      ],
    });
    final CommodityQuote cu = q.firstWhere((CommodityQuote x) => x.code == 'XCU');
    expect(cu.priceUsd, 9500.0);
    expect(cu.quality, PriceQuality.delayed);
    expect(cu.source, 'MetalpriceAPI');
  });

  test('codes the proxy omits are unavailable (never fabricated)', () {
    final List<CommodityQuote> q =
        BackendMarketProvider.parse(specs, <String, dynamic>{'quotes': <dynamic>[]});
    expect(q.every((CommodityQuote x) => x.quality == PriceQuality.unavailable), isTrue);
    expect(q.every((CommodityQuote x) => x.priceUsd == null), isTrue);
  });

  test('null payload yields all unavailable', () {
    final List<CommodityQuote> q = BackendMarketProvider.parse(specs, null);
    expect(q.length, specs.length);
    expect(q.first.quality, PriceQuality.unavailable);
  });
}
