import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/markets/data/split_market_provider.dart';
import 'package:smartbudget/features/markets/data/unavailable_market_provider.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';

/// A source that prices every spec it is given at 1000.
class _Live implements MarketDataProvider {
  final List<String> asked = <String>[];

  @override
  MarketCategory get category => MarketCategory.preciousMetals;

  @override
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs) async {
    asked.addAll(specs.map((CommoditySpec s) => s.code));
    return <CommodityQuote>[
      for (final CommoditySpec s in specs)
        CommodityQuote(
          code: s.code,
          nameEn: s.nameEn,
          nameAr: s.nameAr,
          category: s.category,
          unitLabel: s.unitLabel,
          currency: 'USD',
          priceUsd: 1000,
          source: 'test',
          updatedAt: DateTime(2026),
          quality: PriceQuality.delayed,
        ),
    ];
  }
}

void main() {
  test('platinum and palladium are industrial metals; gold and silver stay',
      () {
    List<String> codes(MarketCategory c) =>
        CommodityConfig.byCategory(c).map((CommoditySpec s) => s.code).toList();
    expect(codes(MarketCategory.preciousMetals), <String>['XAU', 'XAG']);
    expect(
        codes(MarketCategory.industrialMetals).take(2), <String>['XPT', 'XPD']);
  });

  test('each spec goes to its own source, in the order of the specs', () async {
    final _Live live = _Live();
    final SplitMarketProvider p = SplitMarketProvider(
      MarketCategory.industrialMetals,
      byProvider: <String, MarketDataProvider>{'gold_api': live},
      fallback:
          const UnavailableMarketProvider(MarketCategory.industrialMetals),
    );
    final List<CommoditySpec> specs =
        CommodityConfig.byCategory(MarketCategory.industrialMetals);
    final List<CommodityQuote> q = await p.fetch(specs);
    expect(q.map((CommodityQuote x) => x.code),
        specs.map((CommoditySpec s) => s.code));
    expect(live.asked, <String>['XPT', 'XPD']);
    expect(q[0].priceUsd, 1000);
    expect(q[1].priceUsd, 1000);
    // The base metals have no free source: unavailable, never made up.
    expect(q.skip(2).every((CommodityQuote x) => x.priceUsd == null), isTrue);
  });
}
