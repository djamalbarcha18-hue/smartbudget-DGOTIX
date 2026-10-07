import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/settings/domain/base_currency_impact.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

Transaction tx(String id, Money amount, {Money? base}) => Transaction(
      id: id,
      date: DateTime(2026, 9, 10),
      type: TransactionType.expense,
      category: 'الطعام',
      amount: amount,
      baseAmount: base,
      createdAt: DateTime(2026, 9, 10),
    );

void main() {
  group('BaseCurrencyImpact', () {
    final List<Transaction> txns = <Transaction>[
      tx('a', const Money(1000, 'DZD')),
      tx('b', const Money(2000, 'DZD')),
      // Euro wallet spend valued in dinars: counted under DZD and EUR.
      tx('c', const Money(500, 'EUR'), base: const Money(75000, 'DZD')),
      tx('d', const Money(300, 'USD')),
    ];
    final List<BudgetTarget> budgets = <BudgetTarget>[
      BudgetTarget(
        id: 'b1',
        year: 2026,
        month: 9,
        category: 'الطعام',
        planned: const Money(5000, 'DZD'),
        createdAt: DateTime(2026),
      ),
    ];
    final List<Goal> goals = <Goal>[
      Goal(
        id: 'g1',
        name: 'x',
        target: const Money(9000, 'USD'),
        saved: const Money(0, 'USD'),
        createdAt: DateTime(2026),
      ),
    ];

    test('counts what drops out of totals', () {
      final BaseCurrencyImpact i = BaseCurrencyImpact.of(
        from: 'DZD',
        to: 'USD',
        transactions: txns,
        budgets: budgets,
        goals: goals,
      );
      expect(i.transactions, 3);
      expect(i.budgets, 1);
      expect(i.goals, 0);
      expect(i.total, 4);
      expect(i.isEmpty, isFalse);
    });

    test('records already in the new currency stay counted', () {
      final BaseCurrencyImpact i = BaseCurrencyImpact.of(
        from: 'DZD',
        to: 'EUR',
        transactions: txns,
      );
      // 'c' is a EUR transaction: it stays in totals under EUR.
      expect(i.transactions, 2);
    });

    test('same currency or no data means no impact', () {
      expect(
        BaseCurrencyImpact.of(from: 'DZD', to: 'DZD', transactions: txns)
            .isEmpty,
        isTrue,
      );
      expect(BaseCurrencyImpact.of(from: 'DZD', to: 'EUR').isEmpty, isTrue);
    });
    test('transactions the app converts by itself are not counted', () {
      final List<Transaction> sar = <Transaction>[
        tx('s1', const Money(300000, 'SAR')),
        tx('s2', const Money(4500, 'SAR')),
        // Euro spend valued in riyals: euro has no trusted rate offline.
        tx('e1', const Money(1000, 'EUR'), base: const Money(4100, 'SAR')),
      ];
      // Offline: riyal and dollar are pegged, the euro is not.
      expect(
        BaseCurrencyImpact.of(
          from: 'SAR',
          to: 'USD',
          transactions: sar,
          convertible: const FxStatus().trusts,
        ).transactions,
        1,
      );
      // With live rates covering the euro, nothing drops out.
      expect(
        BaseCurrencyImpact.of(
          from: 'SAR',
          to: 'USD',
          transactions: sar,
          convertible:
              const FxStatus(live: true, liveCodes: <String>{'EUR'}).trusts,
        ).transactions,
        0,
      );
      // No rate information: every riyal record is reported.
      expect(
        BaseCurrencyImpact.of(from: 'SAR', to: 'USD', transactions: sar)
            .transactions,
        3,
      );
    });
  });

  group('FxStatus.trusts', () {
    test('USD and its official pegs are trusted offline', () {
      const FxStatus offline = FxStatus();
      for (final String c in <String>[
        'USD',
        'SAR',
        'AED',
        'QAR',
        'BHD',
        'OMR',
        'JOD',
      ]) {
        expect(offline.trusts(c), isTrue, reason: c);
      }
      for (final String c in <String>['KWD', 'EUR', 'DZD', 'EGP']) {
        expect(offline.trusts(c), isFalse, reason: c);
      }
    });

    test('live and hand-entered rates are trusted', () {
      const FxStatus live =
          FxStatus(live: true, liveCodes: <String>{'EUR', 'KWD'});
      expect(live.trusts('EUR'), isTrue);
      expect(live.trusts('KWD'), isTrue);
      expect(live.trusts('DZD'), isFalse);
      // A stale live list is not trusted once the feed is not live.
      expect(const FxStatus(liveCodes: <String>{'EUR'}).trusts('EUR'), isFalse);
      expect(
          const FxStatus(manualCodes: <String>{'DZD'}).trusts('DZD'), isTrue);
    });
  });
}
