import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';

/// The user's metal holdings, kept on the device (in backups and sync).
final metalStoreProvider = Provider<LocalListStore<MetalHolding>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<MetalHolding> store = LocalListStore<MetalHolding>(
    key: 'sb_metals_$userId',
    fromJson: MetalHolding.fromJson,
    toJson: (MetalHolding h) => h.toJson(),
    idOf: (MetalHolding h) => h.id,
    compare: (MetalHolding a, MetalHolding b) =>
        a.createdAt.compareTo(b.createdAt),
  );
  ref.onDispose(store.dispose);
  return store;
});

final metalHoldingsProvider = StreamProvider<List<MetalHolding>>(
    (ref) => ref.watch(metalStoreProvider).watchAll());

final metalActionsProvider = Provider<MetalActions>(
    (ref) => MetalActions(ref.watch(metalStoreProvider)));

class MetalActions {
  MetalActions(this._store);
  final LocalListStore<MetalHolding> _store;

  Future<void> save(MetalHolding h) => _store.upsert(h);
  Future<void> delete(String id) => _store.delete(id);

  static String newId() =>
      'metal-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';
}

/// Prices per gram of pure metal the user entered for their own market
/// (jewellers' prices differ from the world price), in one currency.
class MyMetalPrices {
  const MyMetalPrices({this.currency, this.perGram = const <Metal, double>{}});

  final String? currency;
  final Map<Metal, double> perGram;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currency': currency,
        for (final MapEntry<Metal, double> e in perGram.entries)
          e.key.name: e.value,
      };

  factory MyMetalPrices.fromJson(Map<String, dynamic> j) => MyMetalPrices(
        currency: j['currency'] as String?,
        perGram: <Metal, double>{
          for (final Metal m in Metal.values)
            if (j[m.name] is num && (j[m.name] as num) > 0)
              m: (j[m.name] as num).toDouble(),
        },
      );
}

final myMetalPricesProvider =
    NotifierProvider<MyMetalPricesController, MyMetalPrices>(
        MyMetalPricesController.new);

class MyMetalPricesController extends Notifier<MyMetalPrices> {
  static const String _base = 'sb_metal_prices';

  @override
  MyMetalPrices build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _load(account);
    return const MyMetalPrices();
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(AccountKeys.of(_base, account));
      if (raw == null || raw.isEmpty) return;
      if (ref.read(currentAccountIdProvider) != account) return;
      state = MyMetalPrices.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      // Unreadable: the market price applies.
    }
  }

  /// Sets (or with null, clears) the user's price per gram of pure [m] in
  /// [currency]. Prices kept in another currency are dropped.
  Future<void> set(Metal m, double? perGram, String currency) async {
    final Map<Metal, double> next = state.currency == currency
        ? Map<Metal, double>.of(state.perGram)
        : <Metal, double>{};
    if (perGram == null || perGram <= 0) {
      next.remove(m);
    } else {
      next[m] = perGram;
    }
    state = MyMetalPrices(currency: currency, perGram: next);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          AccountKeys.of(_base, ref.read(currentAccountIdProvider)),
          jsonEncode(state.toJson()));
    } catch (_) {
      // Non-fatal: kept for this session.
    }
  }
}

/// The world quotes for gold, silver and platinum (cached, never fetched on
/// every open; the last ones are kept offline).
final metalQuotesProvider = Provider<Map<Metal, CommodityQuote>>((ref) {
  final List<CommodityQuote> quotes = ref
          .watch(commodityQuotesProvider(MarketCategory.preciousMetals))
          .valueOrNull ??
      const <CommodityQuote>[];
  return <Metal, CommodityQuote>{
    for (final Metal m in Metal.values)
      for (final CommodityQuote q in quotes)
        if (q.code == m.symbol && (q.priceUsd ?? 0) > 0) m: q,
  };
});

/// The price per gram of each pure metal in the base currency: the user's
/// own price when set, else the world price; missing when neither is known.
final metalPricesProvider = Provider<Map<Metal, MetalPrice>>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final Map<String, double> rates = ref.watch(ratesProvider);
  final MyMetalPrices mine = ref.watch(myMetalPricesProvider);
  final Map<Metal, CommodityQuote> quotes = ref.watch(metalQuotesProvider);
  final Map<Metal, MetalPrice> out = <Metal, MetalPrice>{};
  for (final Metal m in Metal.values) {
    final double? own = mine.currency == currency ? mine.perGram[m] : null;
    if (own != null) {
      out[m] = MetalPrice(
          perGram: own, currency: currency, source: MetalPriceSource.mine);
      continue;
    }
    final CommodityQuote? q = quotes[m];
    final double? perGram =
        MetalsValuation.marketPerGram(q?.priceUsd, currency, rates);
    if (perGram != null) {
      out[m] = MetalPrice(
          perGram: perGram,
          currency: currency,
          source: MetalPriceSource.market,
          updatedAt: q?.updatedAt);
    }
  }
  return out;
});

final metalsSummaryProvider =
    Provider<MetalsSummary>((ref) => MetalsValuation.summarize(
          ref.watch(metalHoldingsProvider).valueOrNull ??
              const <MetalHolding>[],
          ref.watch(metalPricesProvider),
          ref.watch(baseCurrencyProvider),
          ref.watch(ratesProvider),
        ));
