import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/exchange_rates/domain/exchange_rate_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

enum WalletType { cash, bank, card, ewallet, savings, other }

/// Somewhere the user keeps money (cash, a bank or postal account, an
/// e-wallet…). "General" always exists and holds everything not assigned to
/// another wallet, so the app works unchanged for people who never add one.
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.opening,
    required this.createdAt,
  });

  static const String generalId = 'general';

  final String id;

  /// Empty for "General" (the app names it).
  final String name;
  final WalletType type;

  /// Balance when the wallet was added (before any recorded transaction).
  /// Its currency is the wallet's currency.
  final Money opening;
  final DateTime createdAt;

  bool get isGeneral => id == generalId;

  String get currency => opening.currencyCode;

  static Wallet general(String currency, {Money? opening}) => Wallet(
        id: generalId,
        name: '',
        type: WalletType.other,
        opening: opening ?? Money.zero(currency),
        createdAt: DateTime(2000),
      );

  Wallet copyWith({String? name, WalletType? type, Money? opening}) => Wallet(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        opening: opening ?? this.opening,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type.name,
        'openingMinor': opening.minorUnits,
        'currency': opening.currencyCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        type: WalletType.values.firstWhere(
            (WalletType t) => t.name == j['type'],
            orElse: () => WalletType.other),
        opening: Money((j['openingMinor'] as num?)?.toInt() ?? 0,
            (j['currency'] as String?) ?? 'USD'),
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
            DateTime(2026),
      );
}

enum MoveKind { transfer, adjustment }

/// Money moving between the user's own wallets (a transfer), or a manual
/// balance correction. Neither is income or expense, so reports ignore them.
class WalletMove {
  const WalletMove({
    required this.id,
    required this.kind,
    required this.date,
    required this.amount,
    required this.toId,
    required this.createdAt,
    this.fromId,
    this.toAmount,
    this.note = '',
  });

  final String id;
  final MoveKind kind;
  final DateTime date;

  /// Positive for a transfer; signed (+/−) for an adjustment.
  final Money amount;

  /// Source wallet of a transfer (null for an adjustment).
  final String? fromId;

  /// Destination of a transfer, or the adjusted wallet.
  final String toId;

  /// What arrived, when the two wallets use different currencies (the real
  /// exchange rate often differs from the official one).
  final Money? toAmount;

  Money get received => toAmount ?? amount;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'amountMinor': amount.minorUnits,
        'currency': amount.currencyCode,
        if (fromId != null) 'fromId': fromId,
        'toId': toId,
        if (toAmount != null) 'toAmountMinor': toAmount!.minorUnits,
        if (toAmount != null) 'toCurrency': toAmount!.currencyCode,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WalletMove.fromJson(Map<String, dynamic> j) {
    final DateTime d = DateTime.tryParse('${j['date']}') ?? DateTime(2026);
    return WalletMove(
      id: j['id'] as String,
      kind: MoveKind.values.firstWhere((MoveKind k) => k.name == j['kind'],
          orElse: () => MoveKind.transfer),
      date: DateTime(d.year, d.month, d.day),
      amount: Money((j['amountMinor'] as num?)?.toInt() ?? 0,
          (j['currency'] as String?) ?? 'USD'),
      fromId: j['fromId'] as String?,
      toId: (j['toId'] as String?) ?? Wallet.generalId,
      toAmount: j['toAmountMinor'] == null
          ? null
          : Money((j['toAmountMinor'] as num).toInt(),
              (j['toCurrency'] as String?) ?? 'USD'),
      note: (j['note'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime(2026),
    );
  }
}

abstract final class WalletMath {
  /// The wallet an id refers to; unknown or missing ids (e.g. a deleted
  /// wallet) count toward "General", so no money ever disappears.
  static String resolve(String? id, Set<String> known) =>
      id != null && known.contains(id) ? id : Wallet.generalId;

  /// Current balance of every wallet, in minor units of that wallet's own
  /// currency. Amounts in another currency than the wallet's are left out
  /// (never silently converted).
  static Map<String, int> balances({
    required List<Wallet> wallets,
    required List<Transaction> txns,
    required List<WalletMove> moves,
  }) {
    final Map<String, Wallet> byId = <String, Wallet>{
      for (final Wallet w in wallets) w.id: w,
    };
    final Set<String> known = byId.keys.toSet();
    final Map<String, int> out = <String, int>{
      for (final Wallet w in wallets) w.id: w.opening.minorUnits,
    };
    void add(String id, Money m) {
      final Wallet? w = byId[id];
      if (w == null || m.currencyCode != w.currency) return;
      out[id] = (out[id] ?? 0) + m.minorUnits;
    }

    for (final Transaction t in txns) {
      final String id = resolve(t.walletId, known);
      add(id, t.isIncome ? t.amount : Money(-t.amount.minorUnits, t.amount.currencyCode));
    }
    for (final WalletMove m in moves) {
      final String to = resolve(m.toId, known);
      if (m.kind == MoveKind.transfer) {
        final String from = resolve(m.fromId, known);
        add(from, Money(-m.amount.minorUnits, m.amount.currencyCode));
        add(to, m.received);
      } else {
        add(to, m.amount);
      }
    }
    return out;
  }

  /// [m] in [to] at the app's rates (units per 1 USD), or null when a rate
  /// is missing.
  static Money? convert(Money m, String to, Map<String, double> ratesVsUsd) {
    if (m.currencyCode == to) return m;
    final double? rf = ratesVsUsd[m.currencyCode];
    final double? rt = ratesVsUsd[to];
    if (rf == null || rt == null || rf <= 0 || rt <= 0) return null;
    return Money.fromDouble(
        ExchangeRateCalculator.convert(
            amount: m.asDouble,
            from: m.currencyCode,
            to: to,
            ratesVsUsd: ratesVsUsd),
        to);
  }

  /// What a foreign-currency [amount] is worth in [base] today, to store on
  /// the transaction; null when it's already in [base] or no rate is known.
  static Money? baseValue(
          Money amount, String base, Map<String, double> ratesVsUsd) =>
      amount.currencyCode == base ? null : convert(amount, base, ratesVsUsd);

  /// Everything in [base]. Wallets whose currency has no rate are left out
  /// and listed in `missing` (never guessed).
  static ({int total, List<String> missing}) totalIn({
    required String base,
    required List<Wallet> wallets,
    required Map<String, int> balances,
    required Map<String, double> ratesVsUsd,
  }) {
    int total = 0;
    final List<String> missing = <String>[];
    for (final Wallet w in wallets) {
      final int b = balances[w.id] ?? 0;
      if (b == 0) continue;
      final Money? c = convert(Money(b, w.currency), base, ratesVsUsd);
      if (c == null) {
        if (!missing.contains(w.currency)) missing.add(w.currency);
      } else {
        total += c.minorUnits;
      }
    }
    return (total: total, missing: missing);
  }

  /// Income and expenses recorded in [walletId] during a month.
  static ({int income, int expense}) monthFlow(
    String walletId,
    List<Transaction> txns,
    Set<String> known,
    String currency,
    int year,
    int month,
  ) {
    int inc = 0;
    int exp = 0;
    for (final Transaction t in txns) {
      if (t.amount.currencyCode != currency ||
          t.date.year != year ||
          t.date.month != month ||
          resolve(t.walletId, known) != walletId) {
        continue;
      }
      if (t.isIncome) {
        inc += t.amount.minorUnits;
      } else {
        exp += t.amount.minorUnits;
      }
    }
    return (income: inc, expense: exp);
  }
}

/// Familiar wallet names, suggested from the base currency. Only shortcuts —
/// the user can name a wallet anything.
abstract final class WalletSuggestions {
  static List<(WalletType, String)> forCurrency(String code) => switch (code) {
        'DZD' => const <(WalletType, String)>[
            (WalletType.bank, 'CCP'),
            (WalletType.ewallet, 'BaridiMob'),
            (WalletType.card, 'Edahabia'),
          ],
        'EGP' => const <(WalletType, String)>[
            (WalletType.ewallet, 'InstaPay'),
            (WalletType.ewallet, 'Vodafone Cash'),
          ],
        'SAR' => const <(WalletType, String)>[
            (WalletType.ewallet, 'STC Pay'),
          ],
        'EUR' || 'USD' || 'GBP' => const <(WalletType, String)>[
            (WalletType.bank, 'Revolut'),
            (WalletType.ewallet, 'PayPal'),
          ],
        _ => const <(WalletType, String)>[],
      };
}
