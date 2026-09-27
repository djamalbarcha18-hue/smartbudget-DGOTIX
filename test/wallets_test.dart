import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

int _n = 0;
Transaction tx(int minor,
        {String? wallet,
        TransactionType type = TransactionType.expense,
        String cur = 'DZD',
        DateTime? date}) =>
    Transaction(
      id: 't${_n++}',
      date: date ?? DateTime(2026, 9, 10),
      type: type,
      category: 'الطعام',
      amount: Money(minor, cur),
      walletId: wallet,
      createdAt: DateTime(2026, 9, 10),
    );

Wallet w(String id, int opening, {WalletType type = WalletType.cash}) => Wallet(
      id: id,
      name: id,
      type: type,
      opening: Money(opening, 'DZD'),
      createdAt: DateTime(2026),
    );

void main() {
  final List<Wallet> wallets = <Wallet>[
    Wallet.general('DZD', opening: const Money(5000, 'DZD')),
    w('cash', 10000),
    w('ccp', 80000, type: WalletType.bank),
  ];

  test('old transactions (no wallet) and unknown wallets count as General', () {
    final Map<String, int> b = WalletMath.balances(
      wallets: wallets,
      txns: <Transaction>[
        tx(1000),
        tx(2000, wallet: 'deleted-wallet'),
        tx(500, wallet: 'cash'),
        tx(30000, wallet: 'ccp', type: TransactionType.income),
      ],
      moves: const <WalletMove>[],
      currency: 'DZD',
    );
    expect(b['general'], 5000 - 1000 - 2000);
    expect(b['cash'], 10000 - 500);
    expect(b['ccp'], 110000);
    expect(WalletMath.total(b), 2000 + 9500 + 110000);
  });

  test('a transfer moves money without changing the total', () {
    final List<WalletMove> moves = <WalletMove>[
      WalletMove(
        id: 'm1',
        kind: MoveKind.transfer,
        date: DateTime(2026, 9, 11),
        amount: const Money(20000, 'DZD'),
        fromId: 'ccp',
        toId: 'cash',
        createdAt: DateTime(2026, 9, 11),
      ),
    ];
    final Map<String, int> before = WalletMath.balances(
        wallets: wallets, txns: const <Transaction>[], moves: const <WalletMove>[], currency: 'DZD');
    final Map<String, int> after = WalletMath.balances(
        wallets: wallets, txns: const <Transaction>[], moves: moves, currency: 'DZD');
    expect(after['ccp'], 60000);
    expect(after['cash'], 30000);
    expect(WalletMath.total(after), WalletMath.total(before));
  });

  test('an adjustment corrects one wallet by a signed amount', () {
    final Map<String, int> b = WalletMath.balances(
      wallets: wallets,
      txns: const <Transaction>[],
      moves: <WalletMove>[
        WalletMove(
          id: 'a1',
          kind: MoveKind.adjustment,
          date: DateTime(2026, 9, 12),
          amount: const Money(-1500, 'DZD'),
          toId: 'cash',
          createdAt: DateTime(2026, 9, 12),
        ),
      ],
      currency: 'DZD',
    );
    expect(b['cash'], 8500);
  });

  test('other currencies are left out (like every total)', () {
    final Map<String, int> b = WalletMath.balances(
      wallets: wallets,
      txns: <Transaction>[tx(999, wallet: 'cash', cur: 'EUR')],
      moves: const <WalletMove>[],
      currency: 'DZD',
    );
    expect(b['cash'], 10000);
  });

  test('month flow per wallet', () {
    final Set<String> known = <String>{'general', 'cash', 'ccp'};
    final ({int income, int expense}) f = WalletMath.monthFlow(
      'cash',
      <Transaction>[
        tx(500, wallet: 'cash'),
        tx(700, wallet: 'cash', date: DateTime(2026, 8, 30)),
        tx(4000, wallet: 'cash', type: TransactionType.income),
        tx(100, wallet: 'ccp'),
      ],
      known,
      'DZD',
      2026,
      9,
    );
    expect(f, (income: 4000, expense: 500));
  });

  test('walletId survives JSON and is omitted when General', () {
    final Transaction t = tx(100, wallet: 'cash');
    expect(Transaction.fromJson(t.toJson()).walletId, 'cash');
    expect(tx(100).toJson().containsKey('walletId'), isFalse);
    expect(Transaction.fromJson(tx(100).toJson()).walletId, isNull);
    expect(t.copyWith(clearWallet: true).walletId, isNull);
  });

  test('wallets and moves survive a backup round trip', () {
    final BackupData back = BackupCodec.decodeJson(BackupCodec.encodeJson(
      BackupData(
        exportedAt: DateTime(2026, 9, 27),
        baseCurrency: 'DZD',
        transactions: <Transaction>[tx(100, wallet: 'ccp')],
        budgets: const [],
        customIncome: const <String>[],
        customExpense: const <String>[],
        wallets: <Wallet>[w('ccp', 80000, type: WalletType.bank)],
        walletMoves: <WalletMove>[
          WalletMove(
            id: 'm1',
            kind: MoveKind.transfer,
            date: DateTime(2026, 9, 11),
            amount: const Money(20000, 'DZD'),
            fromId: 'ccp',
            toId: 'general',
            note: 'سحب',
            createdAt: DateTime(2026, 9, 11),
          ),
        ],
      ),
    ));
    expect(back.transactions.single.walletId, 'ccp');
    expect(back.wallets.single.type, WalletType.bank);
    expect(back.wallets.single.opening.minorUnits, 80000);
    final WalletMove m = back.walletMoves.single;
    expect((m.fromId, m.toId, m.amount.minorUnits, m.note),
        ('ccp', 'general', 20000, 'سحب'));
  });

  test('suggestions follow the base currency', () {
    expect(WalletSuggestions.forCurrency('DZD').map(((WalletType, String) s) => s.$2),
        contains('CCP'));
    expect(WalletSuggestions.forCurrency('XYZ'), isEmpty);
  });
}
