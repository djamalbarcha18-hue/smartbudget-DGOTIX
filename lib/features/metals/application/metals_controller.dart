import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/commodity_models.dart';
import 'package:smartbudget/features/markets/domain/market_category.dart';
import 'package:smartbudget/features/metals/domain/metal_alert.dart';
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
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

/// The world quotes for gold and silver (precious metals) and platinum and
/// palladium (industrial metals) — cached, never fetched on every open; the
/// last ones are kept offline.
final metalQuotesProvider = Provider<Map<Metal, CommodityQuote>>((ref) {
  final List<CommodityQuote> quotes = <CommodityQuote>[
    for (final MarketCategory c in <MarketCategory>[
      MarketCategory.preciousMetals,
      MarketCategory.industrialMetals,
    ])
      ...?ref.watch(commodityQuotesProvider(c)).valueOrNull,
  ];
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

/// Per metal, the average cost of a pure gram against today's price.
final metalAveragesProvider = Provider<Map<Metal, MetalAverage>>(
    (ref) => MetalGains.averages(
          ref.watch(metalHoldingsProvider).valueOrNull ??
              const <MetalHolding>[],
          ref.watch(metalPricesProvider),
          ref.watch(baseCurrencyProvider),
          ref.watch(ratesProvider),
        ));

/// The gains grouped by the year the pieces were bought.
final metalYearGainsProvider = Provider<List<YearGain>>(
    (ref) => MetalGains.byYear(
          ref.watch(metalHoldingsProvider).valueOrNull ??
              const <MetalHolding>[],
          ref.watch(metalPricesProvider),
          ref.watch(baseCurrencyProvider),
          ref.watch(ratesProvider),
        ));

/// A list of [T] kept in the preferences of the signed-in account.
abstract class _AccountList<T> extends Notifier<List<T>> {
  String get base;
  T? decode(Object? j);
  Object encode(T v);

  /// Done once the saved list is read: changes wait for it, so a change
  /// made at start-up never replaces what was saved.
  late Future<void> _ready;

  @override
  List<T> build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _ready = _load(account);
    return <T>[];
  }

  /// Applies [edit] to the list once it is loaded, and saves the result
  /// (nothing when [edit] returns null).
  Future<void> change(List<T>? Function(List<T> now) edit) async {
    await _ready;
    final List<T>? next = edit(state);
    if (next != null) await save(next);
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(AccountKeys.of(base, account));
      if (raw == null || raw.isEmpty) return;
      if (ref.read(currentAccountIdProvider) != account) return;
      final Object? list = jsonDecode(raw);
      if (list is! List) return;
      state = <T>[
        for (final Object? j in list)
          if (decode(j) case final T v) v,
      ];
    } catch (_) {
      // Unreadable: starts empty.
    }
  }

  Future<void> save(List<T> next) async {
    state = next;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          AccountKeys.of(base, ref.read(currentAccountIdProvider)),
          jsonEncode(<Object>[for (final T v in next) encode(v)]));
    } catch (_) {
      // Non-fatal: kept for this session.
    }
  }
}

/// What the user's metals were worth, day by day.
final metalHistoryProvider =
    NotifierProvider<MetalHistoryController, List<MetalPoint>>(
        MetalHistoryController.new);

class MetalHistoryController extends _AccountList<MetalPoint> {
  @override
  String get base => 'sb_metal_history';
  @override
  MetalPoint? decode(Object? j) => MetalPoint.fromJson(j);
  @override
  Object encode(MetalPoint v) => v.toJson();

  /// Keeps today's value of [s], when every holding has a price; and what
  /// was paid for them, when every holding has a cost ([allCosted]).
  Future<void> record(MetalsSummary s, int holdings,
      {bool allCosted = false}) async {
    if (holdings == 0 || s.unpriced.isNotEmpty || s.total.minorUnits <= 0) {
      return;
    }
    final DateTime now = AppClock.now();
    final int? paid = allCosted &&
            s.paidTotal != null &&
            s.paidTotal!.value.minorUnits == s.total.minorUnits
        ? s.paidTotal!.paid.minorUnits
        : null;
    final MetalPoint today = MetalPoint(
        day: DateTime(now.year, now.month, now.day),
        minor: s.total.minorUnits,
        currency: s.total.currencyCode,
        paid: paid);
    await change((List<MetalPoint> now) => now.isNotEmpty &&
            now.last.day == today.day &&
            now.last.minor == today.minor &&
            now.last.currency == today.currency &&
            now.last.paid == today.paid
        ? null
        : MetalHistory.record(now, today));
  }
}

/// Watched where the value is shown: notes today's value in the history.
final metalHistoryRecorderProvider = Provider<void>((ref) {
  bool alive = true;
  ref.onDispose(() => alive = false);
  // Noted just after, never while providers are being built.
  void note(MetalsSummary s) => Future<void>.microtask(() {
        if (!alive) return;
        final List<MetalHolding> holdings =
            ref.read(metalHoldingsProvider).valueOrNull ??
                const <MetalHolding>[];
        ref.read(metalHistoryProvider.notifier).record(s, holdings.length,
            allCosted: MetalGains.withoutCost(holdings) == 0);
      });
  ref.listen<MetalsSummary>(
      metalsSummaryProvider, (_, MetalsSummary s) => note(s),
      fireImmediately: true);
});

/// The user's price alerts: at most one per metal.
final metalAlertsProvider =
    NotifierProvider<MetalAlertsController, List<MetalAlert>>(
        MetalAlertsController.new);

class MetalAlertsController extends _AccountList<MetalAlert> {
  @override
  String get base => 'sb_metal_alerts';
  @override
  MetalAlert? decode(Object? j) => MetalAlert.fromJson(j);
  @override
  Object encode(MetalAlert v) => v.toJson();

  /// Sets the alert of [m] at [target] per gram of pure metal (or with null,
  /// removes it). It fires when the price rises to [target] if that is above
  /// [current], else when it falls to it.
  Future<void> set(Metal m, double? target, String currency,
      {double? current}) {
    return change((List<MetalAlert> now) => <MetalAlert>[
          for (final MetalAlert a in now)
            if (a.metal != m) a,
          if (target != null && target > 0)
            MetalAlert(
                metal: m,
                target: target,
                currency: currency,
                above: current == null || target >= current),
        ]);
  }
}

/// The alerts met by today's prices, for the notifications bell. Prices are
/// only looked up when the user has set an alert.
final metalAlertNoticesProvider = Provider<List<AppAlert>>((ref) {
  final List<MetalAlert> alerts = ref.watch(metalAlertsProvider);
  if (alerts.isEmpty) return const <AppAlert>[];
  final Map<Metal, MetalPrice> prices = ref.watch(metalPricesProvider);
  return <AppAlert>[
    for (final MetalAlert a in alerts)
      if (prices[a.metal] case final MetalPrice p when a.metBy(p))
        AppAlert(
          kind: AlertKind.metalPrice,
          severity: AlertSeverity.info,
          subject: 'metal:${a.metal.name}',
          amount: Money.fromDouble(p.perGram, p.currency),
          compareAmount: Money.fromDouble(a.target, a.currency),
          route: '/metals',
          focusKey: '${a.metal.name}:${a.above ? 'up' : 'down'}:'
              '${Money.fromDouble(a.target, a.currency).minorUnits}${a.currency}',
        ),
  ];
});
