import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';

/// A provider for categories with no reliable FREE source yet (base metals,
/// steel, energy, agriculture). It returns the full commodity list with
/// [PriceQuality.unavailable] and no price, so the UI shows the structure and
/// an honest "unavailable — requires data source" instead of a fake number.
///
/// Replacing it with a licensed/backend provider is a one-line registry change.
class UnavailableMarketProvider implements MarketDataProvider {
  const UnavailableMarketProvider(this.category);

  @override
  final MarketCategory category;

  @override
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs) async {
    final DateTime now = DateTime.now();
    return specs
        .map((CommoditySpec s) => CommodityQuote(
              code: s.code,
              nameEn: s.nameEn,
              nameAr: s.nameAr,
              category: s.category,
              unitLabel: s.unitLabel,
              currency: s.currency,
              benchmark: s.benchmark,
              region: s.region,
              source: s.benchmark ?? 'requires data source',
              updatedAt: now,
              quality: PriceQuality.unavailable,
            ))
        .toList();
  }
}
