import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/markets/data/backend_market_provider.dart';
import 'package:smartbudget/features/markets/data/coingecko_crypto_repository.dart';
import 'package:smartbudget/features/markets/data/dolarapi_ar_repository.dart';
import 'package:smartbudget/features/markets/data/gold_api_metals_repository.dart';
import 'package:smartbudget/features/markets/data/market_http.dart';
import 'package:smartbudget/features/markets/data/open_erapi_fx_repository.dart';
import 'package:smartbudget/features/markets/data/rate_cache.dart';
import 'package:smartbudget/features/markets/data/unavailable_market_provider.dart';
import 'package:smartbudget/features/markets/domain/commodity_config.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/markets/domain/market_config.dart';
import 'package:smartbudget/features/markets/domain/market_data_provider.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';
import 'package:smartbudget/features/markets/domain/market_repository.dart';

// ---- Infrastructure ----
final marketHttpProvider = Provider<MarketHttp>((ref) => const MarketHttp());
final rateCacheProvider = Provider<RateCache>((ref) => const RateCache());

// ---- Repositories (swap for backend-backed impls later; interface stays) ----
final fxRatesRepositoryProvider = Provider<FxRatesRepository>((ref) =>
    OpenErApiFxRepository(
        http: ref.watch(marketHttpProvider), cache: ref.watch(rateCacheProvider)));

final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) =>
    CoinGeckoCryptoRepository(
        http: ref.watch(marketHttpProvider), cache: ref.watch(rateCacheProvider)));

/// Registered parallel-market sources by id. Countries whose id is absent here
/// render "unavailable" (no fabricated numbers).
final parallelRepositoriesProvider =
    Provider<Map<String, ParallelMarketRepository>>((ref) {
  final MarketHttp http = ref.watch(marketHttpProvider);
  final RateCache cache = ref.watch(rateCacheProvider);
  return <String, ParallelMarketRepository>{
    'dolarapi_ar': DolarApiArRepository(http: http, cache: cache),
  };
});

// ---- Live data (cached; never fetched on every page open) ----
final fxSnapshotProvider = FutureProvider<FxSnapshot>((ref) {
  ref.keepAlive();
  return ref.watch(fxRatesRepositoryProvider).latestVsUsd();
});

final cryptoQuotesProvider = FutureProvider<List<CryptoQuote>>((ref) {
  ref.keepAlive();
  final String base = ref.watch(baseCurrencyProvider);
  return ref.watch(cryptoRepositoryProvider).quotes(MarketConfig.crypto, base);
});

final parallelQuotesProvider =
    FutureProvider.family<List<FxQuote>, String>((ref, String countryCode) {
  ref.keepAlive();
  final CountryMarket market = MarketConfig.countries
      .firstWhere((CountryMarket c) => c.country == countryCode);
  final ParallelMarketRepository? repo =
      ref.watch(parallelRepositoriesProvider)[market.parallelSourceId];
  if (repo == null) return Future<List<FxQuote>>.value(const <FxQuote>[]);
  return repo.quotes(market);
});

// ---- Commodities & metals (category-based providers) ----

/// Registry of one data provider per market category. Precious metals are live
/// (free); the other commodity categories use the "unavailable" provider until
/// a licensed/backend source is wired — swapping is a one-line change here.
final marketProvidersProvider =
    Provider<Map<MarketCategory, MarketDataProvider>>((ref) {
  final MarketHttp http = ref.watch(marketHttpProvider);
  final RateCache cache = ref.watch(rateCacheProvider);

  // Categories with no free client-side source. When the OWNER has configured a
  // market proxy (server-side keys + provider choice), fetch live from it; else
  // render "unavailable" — never a fabricated number.
  MarketDataProvider deferred(MarketCategory category) => AppEnv.hasMarketApi
      ? BackendMarketProvider(category, AppEnv.marketApiUrl,
          http: http, cache: cache)
      : UnavailableMarketProvider(category);

  return <MarketCategory, MarketDataProvider>{
    // Precious metals: live free source (gold-api.com).
    MarketCategory.preciousMetals:
        GoldApiMetalsRepository(http: http, cache: cache),
    MarketCategory.industrialMetals: deferred(MarketCategory.industrialMetals),
    MarketCategory.steelIron: deferred(MarketCategory.steelIron),
    MarketCategory.energy: deferred(MarketCategory.energy),
    MarketCategory.agriculture: deferred(MarketCategory.agriculture),
  };
});

/// Quotes for one commodity category (cached; never fetched on every open).
final commodityQuotesProvider =
    FutureProvider.family<List<CommodityQuote>, MarketCategory>(
        (ref, MarketCategory category) {
  ref.keepAlive();
  final MarketDataProvider? provider =
      ref.watch(marketProvidersProvider)[category];
  if (provider == null) return Future<List<CommodityQuote>>.value(const <CommodityQuote>[]);
  return provider.fetch(CommodityConfig.byCategory(category));
});

/// The currently selected Markets tab/category.
final selectedMarketCategoryProvider =
    StateProvider<MarketCategory>((ref) => MarketCategory.exchangeRates);

const List<MarketCategory> _commodityCategories = <MarketCategory>[
  MarketCategory.preciousMetals,
  MarketCategory.industrialMetals,
  MarketCategory.steelIron,
  MarketCategory.energy,
  MarketCategory.agriculture,
];

/// Clears the market cache and refetches everything (manual refresh).
Future<void> refreshMarkets(Ref ref) async {
  await ref.read(rateCacheProvider).clearAll();
  ref.invalidate(fxSnapshotProvider);
  ref.invalidate(cryptoQuotesProvider);
  for (final CountryMarket c in MarketConfig.countries) {
    ref.invalidate(parallelQuotesProvider(c.country));
  }
  for (final MarketCategory cat in _commodityCategories) {
    ref.invalidate(commodityQuotesProvider(cat));
  }
}

final refreshMarketsProvider = Provider<Future<void> Function()>((ref) {
  return () => refreshMarkets(ref);
});

// ---- Rate Type selection (Official / Parallel / P2P / Custom), persisted ----
final rateTypeProvider =
    NotifierProvider<RateTypeController, MarketType>(RateTypeController.new);

class RateTypeController extends Notifier<MarketType> {
  static const String _key = 'sb_rate_type';

  @override
  MarketType build() {
    _load();
    return MarketType.official;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw != null) {
        state = MarketType.values.firstWhere((MarketType t) => t.name == raw,
            orElse: () => MarketType.official);
      }
    } catch (_) {
      // Keep default.
    }
  }

  Future<void> set(MarketType type) async {
    state = type;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, type.name);
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// A user-supplied custom valuation rate (base units per 1 USD), persisted.
/// Only used when Rate Type = Custom. Null until the user sets it.
final customRateProvider =
    NotifierProvider<CustomRateController, double?>(CustomRateController.new);

class CustomRateController extends Notifier<double?> {
  static const String _key = 'sb_custom_rate';

  @override
  double? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final double? v = p.getDouble(_key);
      if (v != null && v > 0) state = v;
    } catch (_) {
      // Keep default.
    }
  }

  Future<void> set(double? value) async {
    state = (value != null && value > 0) ? value : null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (state != null) {
        await p.setDouble(_key, state!);
      } else {
        await p.remove(_key);
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}
