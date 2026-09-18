import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';

/// One data source for a market category (precious metals, base metals, steel,
/// energy, agriculture…). Providers are independent and swappable — a licensed
/// or backend-backed source can replace a free/unavailable one without touching
/// the engine or UI.
abstract interface class MarketDataProvider {
  MarketCategory get category;

  /// Quotes for the given specs. Implementations that have no reliable source
  /// return quotes with [PriceQuality.unavailable] and a null price (never a
  /// fabricated number).
  Future<List<CommodityQuote>> fetch(List<CommoditySpec> specs);
}
