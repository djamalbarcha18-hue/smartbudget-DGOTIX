import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
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

int sum(Map<String, int> b) => b.values.fold(0, (int a, int x) => a + x);

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
    );
    expect(b['general'], 5000 - 1000 - 2000);
    expect(b['cash'], 10000 - 500);
    expect(b['ccp'], 110000);
    expect(sum(b), 2000 + 9500 + 110000);
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
        wallets: wallets, txns: const <Transaction>[], moves: const <WalletMove>[]);
    final Map<String, int> after = WalletMath.balances(
        wallets: wallets, txns: const <Transaction>[], moves: moves);
    expect(after['ccp'], 60000);
    expect(after['cash'], 30000);
    expect(sum(after), sum(before));
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
    );
    expect(b['cash'], 8500);
  });

  test('other currencies are left out (like every total)', () {
    final Map<String, int> b = WalletMath.balances(
      wallets: wallets,
      txns: <Transaction>[tx(999, wallet: 'cash', cur: 'EUR')],
      moves: const <WalletMove>[],
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

  group('multi-currency', () {
    final Wallet eur = Wallet(
      id: 'eur',
      name: 'Revolut',
      type: WalletType.bank,
      opening: const Money(100000, 'EUR'), // 1,000.00 €
      createdAt: DateTime(2026),
    );
    final List<Wallet> ws = <Wallet>[
      Wallet.general('DZD', opening: const Money(5000000, 'DZD')), // 50,000 DA
      eur,
    ];
    const Map<String, double> rates = <String, double>{
      'USD': 1, 'DZD': 134.5, 'EUR': 0.92,
    };

    test('each wallet keeps its own currency', () {
      final Map<String, int> b = WalletMath.balances(
        wallets: ws,
        txns: <Transaction>[
          tx(2500, wallet: 'eur', cur: 'EUR'), // 25.00 € spent
          tx(100000), // 1,000 DA from General
          tx(999, wallet: 'eur'), // a DZD amount in the EUR wallet: ignored
        ],
        moves: const <WalletMove>[],
      );
      expect(b['eur'], 97500);
      expect(b['general'], 4900000);
    });

    test('a cross-currency transfer uses the amount actually received', () {
      final Map<String, int> b = WalletMath.balances(
        wallets: ws,
        txns: const <Transaction>[],
        moves: <WalletMove>[
          WalletMove(
            id: 'x',
            kind: MoveKind.transfer,
            date: DateTime(2026, 9, 20),
            amount: const Money(20000, 'EUR'), // 200 €
            toAmount: const Money(5000000, 'DZD'), // 50,000 DA (parallel rate)
            fromId: 'eur',
            toId: 'general',
            createdAt: DateTime(2026, 9, 20),
          ),
        ],
      );
      expect(b['eur'], 80000);
      expect(b['general'], 10000000);
    });

    test('the total converts to the base currency', () {
      final ({int total, List<String> missing}) t = WalletMath.totalIn(
        base: 'DZD',
        wallets: ws,
        balances: <String, int>{'general': 5000000, 'eur': 92000},
        ratesVsUsd: rates,
      );
      // 920 € = 1,000 USD = 134,500 DA; + 50,000 DA.
      expect(t.total, 18450000);
      expect(t.missing, isEmpty);
    });

    test('a currency without a rate is flagged, never guessed', () {
      final ({int total, List<String> missing}) t = WalletMath.totalIn(
        base: 'DZD',
        wallets: ws,
        balances: <String, int>{'general': 5000000, 'eur': 92000},
        ratesVsUsd: const <String, double>{'USD': 1, 'DZD': 134.5},
      );
      expect(t.total, 5000000);
      expect(t.missing, <String>['EUR']);
    });

    test('the received amount survives JSON', () {
      final WalletMove m = WalletMove(
        id: 'x',
        kind: MoveKind.transfer,
        date: DateTime(2026, 9, 20),
        amount: const Money(20000, 'EUR'),
        toAmount: const Money(5000000, 'DZD'),
        fromId: 'eur',
        toId: 'general',
        createdAt: DateTime(2026, 9, 20),
      );
      final WalletMove r = WalletMove.fromJson(m.toJson());
      expect(r.received.minorUnits, 5000000);
      expect(r.received.currencyCode, 'DZD');
      expect(r.amount.currencyCode, 'EUR');
    });
  });

  group('reports include foreign-currency transactions', () {
    Transaction eurSpend(int minor, int baseMinor) => Transaction(
          id: 'e${_n++}',
          date: DateTime(2026, 9, 10),
          type: TransactionType.expense,
          category: 'المطاعم',
          amount: Money(minor, 'EUR'),
          baseAmount: Money(baseMinor, 'DZD'),
          walletId: 'eur',
          createdAt: DateTime(2026, 9, 10),
        );

    test('inCurrency uses the value recorded on the day', () {
      final Transaction t = eurSpend(1000, 250000);
      expect(t.inCurrency('EUR'), same(t));
      final Transaction? d = t.inCurrency('DZD');
      expect(d!.amount, const Money(250000, 'DZD'));
      expect(d.category, 'المطاعم');
      expect(t.inCurrency('USD'), isNull);
    });

    test('summaries and category totals count them in the base currency', () {
      final List<Transaction> txns = <Transaction>[
        tx(100000, type: TransactionType.income), // 1,000 DA income
        tx(20000), // 200 DA food
        eurSpend(1000, 250000), // 10 € dining = 2,500 DA
        Transaction(
          id: 'nobase',
          date: DateTime(2026, 9, 10),
          type: TransactionType.expense,
          category: 'المطاعم',
          amount: const Money(500, 'EUR'),
          createdAt: DateTime(2026, 9, 10),
        ), // no recorded value: left out, never guessed
      ];
      final FinanceSummary s = FinanceCalculator.summarize(txns, 'DZD');
      expect(s.expense.minorUnits, 270000);
      expect(s.income.minorUnits, 100000);
      final List<CategoryTotal> cats = FinanceCalculator.categoryTotals(
          txns, TransactionType.expense, 'DZD');
      expect(cats.first.category, 'المطاعم');
      expect(cats.first.amount.minorUnits, 250000);
    });

    test('the recorded value survives JSON', () {
      final Transaction r = Transaction.fromJson(eurSpend(1000, 250000).toJson());
      expect(r.baseAmount, const Money(250000, 'DZD'));
      expect(tx(100).toJson().containsKey('baseMinor'), isFalse);
    });

    test('baseValue is null for base-currency amounts', () {
      const Map<String, double> rates = <String, double>{'USD': 1, 'DZD': 134.5, 'EUR': 0.92};
      expect(WalletMath.baseValue(const Money(100, 'DZD'), 'DZD', rates), isNull);
      expect(WalletMath.baseValue(const Money(9200, 'EUR'), 'DZD', rates),
          const Money(1345000, 'DZD'));
    });
  });
}
