import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';

/// A category whose commodities come from more than one source: each spec
/// goes to the provider named by its `providerId`, the rest to [fallback].
/// Quotes come back in the order of the specs.
///
/// Industrial metals use it: platinum and palladium are live from the free
/// precious-metals source, the exchange-priced base metals wait for theirs.
class SplitMarketProvider implements MarketDataProvider {
  const SplitMarketProvider(this.category,
      {required this.byProvider, required this.fallback});

  @override
  final MarketCategory category;
  final Map<String, MarketDataProvider> byProvider;
  final MarketDataProvider fallback;

  @override
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs) async {
    final Map<MarketDataProvider, List<CommoditySpec>> groups =
        <MarketDataProvider, List<CommoditySpec>>{};
    for (final CommoditySpec s in specs) {
      (groups[byProvider[s.providerId] ?? fallback] ??= <CommoditySpec>[])
          .add(s);
    }
    final Map<String, CommodityQuote> byCode = <String, CommodityQuote>{};
    for (final MapEntry<MarketDataProvider, List<CommoditySpec>> g
        in groups.entries) {
      for (final CommodityQuote q in await g.key.fetch(g.value)) {
        byCode[q.code] = q;
      }
    }
    return <CommodityQuote>[
      for (final CommoditySpec s in specs)
        if (byCode[s.code] case final CommodityQuote q) q,
    ];
  }
}
