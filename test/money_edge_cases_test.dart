import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// Known answers for the money math, at the edges.
void main() {
  Transaction t(String id, TransactionType type, Money m, {Money? base}) =>
      Transaction(
        id: id,
        date: DateTime(2026, 10, 1),
        type: type,
        category: 'الطعام',
        amount: m,
        baseAmount: base,
        createdAt: DateTime(2026, 10, 1),
      );

  test('amounts typed with decimals become exact minor units', () {
    expect(Money.fromDouble(19.99, 'USD').minorUnits, 1999);
    expect(Money.fromDouble(0.1 + 0.2, 'USD').minorUnits, 30);
    expect(Money.fromDouble(1234567.89, 'SAR').minorUnits, 123456789);
    expect(Money.fromDouble(12.345, 'KWD').minorUnits, 12345); // 3 decimals
    expect(Money.fromDouble(1500, 'JPY').minorUnits, 1500); // no decimals
    expect(Money.fromDouble(9999999999.99, 'USD').minorUnits, 999999999999);
  });

  test('sums are exact: a thousand 0.10 make 100.00', () {
    final List<Transaction> txns = <Transaction>[
      for (int i = 0; i < 1000; i++)
        t('e$i', TransactionType.expense, Money.fromDouble(0.10, 'USD')),
    ];
    expect(FinanceCalculator.summarize(txns, 'USD').expense,
        const Money(10000, 'USD'));
  });

  test('income, expense, net and savings rate', () {
    final FinanceSummary s = FinanceCalculator.summarize(<Transaction>[
      t('i', TransactionType.income, const Money(500000, 'SAR')),
      t('e1', TransactionType.expense, const Money(125050, 'SAR')),
      t('e2', TransactionType.expense, const Money(74950, 'SAR')),
    ], 'SAR');
    expect(s.income, const Money(500000, 'SAR'));
    expect(s.expense, const Money(200000, 'SAR'));
    expect(s.net, const Money(300000, 'SAR'));
    expect(s.savingsRate, closeTo(0.6, 1e-12));
  });

  test('spending more than earned: a negative net; no income: rate 0', () {
    final FinanceSummary over = FinanceCalculator.summarize(<Transaction>[
      t('i', TransactionType.income, const Money(1000, 'USD')),
      t('e', TransactionType.expense, const Money(1500, 'USD')),
    ], 'USD');
    expect(over.net, const Money(-500, 'USD'));
    expect(over.savingsRate, closeTo(-0.5, 1e-12));
    final FinanceSummary none = FinanceCalculator.summarize(<Transaction>[
      t('e', TransactionType.expense, const Money(1500, 'USD')),
    ], 'USD');
    expect(none.savingsRate, 0);
    expect(FinanceCalculator.summarize(const <Transaction>[], 'USD').net,
        const Money(0, 'USD'));
  });

  test('another currency counts at the base value recorded, never guessed', () {
    final FinanceSummary s = FinanceCalculator.summarize(<Transaction>[
      t('sar', TransactionType.expense, const Money(10000, 'SAR')),
      // $20 recorded as 75.00 SAR on the day.
      t('usd', TransactionType.expense, const Money(2000, 'USD'),
          base: const Money(7500, 'SAR')),
      // ¥3,000 with no rate known: left out.
      t('jpy', TransactionType.expense, const Money(3000, 'JPY')),
    ], 'SAR');
    expect(s.expense, const Money(17500, 'SAR'));
    expect(s.count, 2);
  });

  test('exchange: through the rates, rounded to the target currency', () {
    const Map<String, double> rates = <String, double>{
      'USD': 1,
      'SAR': 3.75,
      'KWD': 0.3075,
      'JPY': 150,
    };
    expect(WalletMath.convert(const Money(10000, 'USD'), 'SAR', rates),
        const Money(37500, 'SAR'));
    expect(WalletMath.convert(const Money(10000, 'USD'), 'KWD', rates),
        const Money(30750, 'KWD'));
    expect(WalletMath.convert(const Money(100, 'USD'), 'JPY', rates),
        const Money(150, 'JPY'));
    expect(WalletMath.convert(const Money(100, 'USD'), 'EUR', rates), isNull);
  });

  test('wallet balances follow additions, edits and deletions', () {
    final Wallet w = Wallet(
        id: 'w',
        name: 'Bank',
        type: WalletType.bank,
        opening: const Money(100000, 'SAR'),
        createdAt: DateTime(2026));
    int balance(List<Transaction> txns) => WalletMath.balances(
        wallets: <Wallet>[Wallet.general('SAR'), w],
        txns: txns,
        moves: const <WalletMove>[])['w']!;
    final Transaction salary =
        t('i', TransactionType.income, const Money(500000, 'SAR'))
            .copyWith(walletId: 'w');
    final Transaction rent =
        t('e', TransactionType.expense, const Money(300000, 'SAR'))
            .copyWith(walletId: 'w');
    expect(balance(<Transaction>[salary, rent]), 300000);
    expect(
        balance(<Transaction>[
          salary,
          rent.copyWith(amount: const Money(250000, 'SAR'))
        ]),
        350000);
    expect(balance(<Transaction>[salary]), 600000);
  });
}
