import 'package:smartbudget/core/money/money.dart';
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
  final Money opening;
  final DateTime createdAt;

  bool get isGeneral => id == generalId;

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

  /// Current balance of every wallet, in minor units of [currency]. Only
  /// amounts in [currency] count (like every total in the app).
  static Map<String, int> balances({
    required List<Wallet> wallets,
    required List<Transaction> txns,
    required List<WalletMove> moves,
    required String currency,
  }) {
    final Set<String> known = <String>{for (final Wallet w in wallets) w.id};
    final Map<String, int> out = <String, int>{
      for (final Wallet w in wallets)
        w.id: w.opening.currencyCode == currency ? w.opening.minorUnits : 0,
    };
    out.putIfAbsent(Wallet.generalId, () => 0);
    for (final Transaction t in txns) {
      if (t.amount.currencyCode != currency) continue;
      final String id = resolve(t.walletId, known);
      out[id] = out[id]! +
          (t.isIncome ? t.amount.minorUnits : -t.amount.minorUnits);
    }
    for (final WalletMove m in moves) {
      if (m.amount.currencyCode != currency) continue;
      final String to = resolve(m.toId, known);
      if (m.kind == MoveKind.transfer) {
        final String from = resolve(m.fromId, known);
        out[from] = out[from]! - m.amount.minorUnits;
      }
      out[to] = out[to]! + m.amount.minorUnits;
    }
    return out;
  }

  static int total(Map<String, int> balances) =>
      balances.values.fold(0, (int a, int b) => a + b);

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
