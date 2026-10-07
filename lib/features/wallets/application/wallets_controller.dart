import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

String _uid(Ref ref) => ref.watch(authControllerProvider).user?.id ?? 'guest';

final walletStoreProvider = Provider<LocalListStore<Wallet>>((ref) {
  final LocalListStore<Wallet> store = LocalListStore<Wallet>(
    key: 'sb_wallets_${_uid(ref)}',
    fromJson: Wallet.fromJson,
    toJson: (Wallet w) => w.toJson(),
    idOf: (Wallet w) => w.id,
    compare: (Wallet a, Wallet b) => a.createdAt.compareTo(b.createdAt),
  );
  ref.onDispose(store.dispose);
  return store;
});

final walletMoveStoreProvider = Provider<LocalListStore<WalletMove>>((ref) {
  final LocalListStore<WalletMove> store = LocalListStore<WalletMove>(
    key: 'sb_wallet_moves_${_uid(ref)}',
    fromJson: WalletMove.fromJson,
    toJson: (WalletMove m) => m.toJson(),
    idOf: (WalletMove m) => m.id,
    compare: (WalletMove a, WalletMove b) {
      final int d = b.date.compareTo(a.date);
      return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
    },
  );
  ref.onDispose(store.dispose);
  return store;
});

final _storedWalletsProvider = StreamProvider<List<Wallet>>(
    (ref) => ref.watch(walletStoreProvider).watchAll());

final walletMovesProvider = StreamProvider<List<WalletMove>>(
    (ref) => ref.watch(walletMoveStoreProvider).watchAll());

/// Every wallet, "General" first (it always exists).
final walletsProvider = Provider<List<Wallet>>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final List<Wallet> stored =
      ref.watch(_storedWalletsProvider).valueOrNull ?? const <Wallet>[];
  // General always uses the base currency (its stored opening balance only
  // counts while that currency matches).
  final Wallet? stored0 =
      stored.where((Wallet w) => w.isGeneral).firstOrNull;
  final Wallet general = stored0 != null && stored0.currency == currency
      ? stored0
      : Wallet.general(currency);
  return <Wallet>[
    general,
    ...stored.where((Wallet w) => !w.isGeneral),
  ];
});

/// True once the user has added a wallet of their own.
final hasWalletsProvider =
    Provider<bool>((ref) => ref.watch(walletsProvider).length > 1);

/// Each wallet's balance, in minor units of that wallet's own currency.
final walletBalancesProvider = Provider<Map<String, int>>((ref) {
  return WalletMath.balances(
    wallets: ref.watch(walletsProvider),
    txns: ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[],
    moves: ref.watch(walletMovesProvider).valueOrNull ?? const <WalletMove>[],
  );
});

/// All wallets together in the base currency, at the app's exchange rates.
final walletTotalProvider =
    Provider<({int total, List<String> missing})>((ref) {
  return WalletMath.totalIn(
    base: ref.watch(baseCurrencyProvider),
    wallets: ref.watch(walletsProvider),
    balances: ref.watch(walletBalancesProvider),
    ratesVsUsd: ref.watch(ratesProvider),
  );
});

/// Currency of a wallet id (unknown ids resolve to General = base currency).
final walletCurrencyProvider = Provider.family<String, String?>((ref, id) {
  final List<Wallet> wallets = ref.watch(walletsProvider);
  final Set<String> known = <String>{for (final Wallet w in wallets) w.id};
  final String rid = WalletMath.resolve(id, known);
  return wallets.firstWhere((Wallet w) => w.id == rid).currency;
});

/// The wallet new transactions go to (General unless the user picks one).
final defaultWalletProvider =
    NotifierProvider<DefaultWalletController, String>(DefaultWalletController.new);

class DefaultWalletController extends Notifier<String> {
  late String _key;

  @override
  String build() {
    _key = 'sb_default_wallet_${_uid(ref)}';
    _load();
    return Wallet.generalId;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      state = p.getString(_key) ?? Wallet.generalId;
    } catch (_) {
      // Keep General.
    }
  }

  Future<void> set(String id) async {
    state = id;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, id);
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The default wallet, if it still exists (else General).
final effectiveDefaultWalletProvider = Provider<String>((ref) {
  final Set<String> known = <String>{
    for (final Wallet w in ref.watch(walletsProvider)) w.id,
  };
  return WalletMath.resolve(ref.watch(defaultWalletProvider), known);
});

final walletActionsProvider = Provider<WalletActions>(WalletActions.new);

class WalletActions {
  WalletActions(this._ref);
  final Ref _ref;

  static String _id(String prefix) =>
      '$prefix-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  static String newWalletId() => _id('wallet');

  Future<void> save(Wallet w) => _ref.read(walletStoreProvider).upsert(w);

  /// Removes a wallet. Its transactions and transfers then count toward
  /// General (nothing is lost from the total).
  Future<void> delete(String id) async {
    if (id == Wallet.generalId) return;
    await _ref.read(walletStoreProvider).delete(id);
    if (_ref.read(defaultWalletProvider) == id) {
      await _ref.read(defaultWalletProvider.notifier).set(Wallet.generalId);
    }
  }

  Future<void> transfer({
    required String fromId,
    required String toId,
    required Money amount,
    required DateTime date,
    Money? toAmount,
    String note = '',
  }) =>
      _ref.read(walletMoveStoreProvider).upsert(WalletMove(
            id: _id('move'),
            kind: MoveKind.transfer,
            date: DateTime(date.year, date.month, date.day),
            amount: amount,
            fromId: fromId,
            toId: toId,
            toAmount: toAmount != null &&
                    toAmount.currencyCode != amount.currencyCode
                ? toAmount
                : null,
            note: note,
            createdAt: AppClock.now(),
          ));

  /// Corrects [walletId] by [delta] without touching income or expenses.
  Future<void> adjust(String walletId, Money delta) =>
      _ref.read(walletMoveStoreProvider).upsert(WalletMove(
            id: _id('adjust'),
            kind: MoveKind.adjustment,
            date: _today(),
            amount: delta,
            toId: walletId,
            createdAt: AppClock.now(),
          ));

  /// Records the difference found when reconciling as a real transaction:
  /// money missing becomes an expense, extra money an income.
  Future<void> recordDifference(
      String walletId, Money delta, String description) {
    final bool extra = delta.minorUnits > 0;
    final Money amount = Money(delta.minorUnits.abs(), delta.currencyCode);
    return _ref.read(transactionActionsProvider).add(Transaction(
          id: TransactionActions.newId(),
          date: _today(),
          type: extra ? TransactionType.income : TransactionType.expense,
          category: 'أخرى',
          amount: amount,
          baseAmount: WalletMath.baseValue(amount,
              _ref.read(baseCurrencyProvider), _ref.read(ratesProvider)),
          description: description,
          walletId: walletId == Wallet.generalId ? null : walletId,
          createdAt: AppClock.now(),
        ));
  }

  Future<void> deleteMove(String id) =>
      _ref.read(walletMoveStoreProvider).delete(id);

  static DateTime _today() {
    final DateTime n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }
}


/// Foreign-currency transactions with no value in the current base currency
/// get one, once its rate can be trusted (USD, a USD peg, live or entered by
/// hand — never the rough built-in defaults). That covers transactions saved
/// before base values were recorded and those valued in a previous base
/// currency. Runs whenever rates, transactions or the base currency change and
/// only touches transactions still missing a value.
final baseValueBackfillProvider = Provider<void>((ref) {
  final String base = ref.watch(baseCurrencyProvider);
  // The base currency is USD until the saved one is read: valuing anything
  // in it before then would rewrite records against the wrong currency.
  if (!ref.watch(baseCurrencyLoadedProvider)) return;
  final FxStatus fx = ref.watch(fxStatusProvider);
  final List<Transaction> txns =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final Map<String, double> rates = ref.watch(ratesProvider);
  final List<Transaction> fixes = <Transaction>[];
  for (final Transaction t in txns) {
    final String cur = t.amount.currencyCode;
    if (t.inCurrency(base) != null) continue;
    if (!fx.trusts(cur) || !fx.trusts(base)) continue;
    final Money? v = WalletMath.baseValue(t.amount, base, rates);
    if (v != null) fixes.add(t.copyWith(baseAmount: v));
  }
  if (fixes.isEmpty) return;
  final TransactionActions actions = ref.read(transactionActionsProvider);
  Future<void>.microtask(() async {
    for (final Transaction t in fixes) {
      await actions.update(t);
    }
  });
});
