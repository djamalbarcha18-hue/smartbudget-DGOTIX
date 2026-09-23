import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/notifications/domain/smart_alerts.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

int _seq = 0;

Transaction tx(
  DateTime date,
  String category,
  double amount, {
  TransactionType type = TransactionType.expense,
  String? id,
  String currency = 'USD',
}) =>
    Transaction(
      id: id ?? 'txn-${_seq++}',
      date: date,
      type: type,
      category: category,
      amount: Money.fromDouble(amount, currency),
      createdAt: date,
    );

void main() {
  group('budget forecast', () {
    // 10 September 2026: 10 of 30 days gone.
    final DateTime now = DateTime(2026, 9, 10, 12);

    test('warns when the pace will pass the budget', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 9, 2), 'food', 50),
        tx(DateTime(2026, 9, 5), 'food', 50),
        tx(DateTime(2026, 9, 8), 'food', 50),
      ];
      // 150 in 10 days ⇒ ~450 by month end against a 300 budget.
      final List<AppAlert> a = SmartAlertEngine.budgetForecasts(
          txns, <String, int>{'food': 30000}, 'USD', now);
      expect(a.single.kind, AlertKind.budgetForecast);
      expect(a.single.subject, 'food');
      expect(a.single.amount, const Money(15000, 'USD'));
    });

    test('recurring items count once instead of being projected', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 9, 1), 'housing', 700,
            id: 'rec-rule-rent-20260901'),
        tx(DateTime(2026, 9, 3), 'housing', 10),
        tx(DateTime(2026, 9, 5), 'housing', 10),
        tx(DateTime(2026, 9, 7), 'housing', 10),
      ];
      // 700 fixed + 30 × 3 = 790 ≤ 1100 budget × 1.1 — no forecast.
      expect(
          SmartAlertEngine.budgetForecasts(
              txns, <String, int>{'housing': 100000}, 'USD', now),
          isEmpty);
    });

    test('too early, too few expenses, or already near budget ⇒ nothing', () {
      final List<Transaction> two = <Transaction>[
        tx(DateTime(2026, 9, 2), 'food', 80),
        tx(DateTime(2026, 9, 3), 'food', 80),
      ];
      expect(
          SmartAlertEngine.budgetForecasts(
              two, <String, int>{'food': 30000}, 'USD', now),
          isEmpty);
      final List<Transaction> early = <Transaction>[
        tx(DateTime(2026, 9, 1), 'food', 40),
        tx(DateTime(2026, 9, 2), 'food', 40),
        tx(DateTime(2026, 9, 3), 'food', 40),
      ];
      expect(
          SmartAlertEngine.budgetForecasts(early, <String, int>{'food': 30000},
              'USD', DateTime(2026, 9, 3)),
          isEmpty);
      final List<Transaction> near = <Transaction>[
        tx(DateTime(2026, 9, 2), 'food', 100),
        tx(DateTime(2026, 9, 5), 'food', 100),
        tx(DateTime(2026, 9, 8), 'food', 80),
      ];
      expect(
          SmartAlertEngine.budgetForecasts(
              near, <String, int>{'food': 30000}, 'USD', now),
          isEmpty);
    });
  });

  group('unusual spending', () {
    final DateTime now = DateTime(2026, 9, 23);

    test('flags a recent expense far above the category median', () {
      final List<Transaction> txns = <Transaction>[
        for (int i = 1; i <= 5; i++) tx(DateTime(2026, 8, i * 3), 'food', 20),
        tx(DateTime(2026, 9, 21), 'food', 90, id: 'big'),
      ];
      final List<AppAlert> a =
          SmartAlertEngine.unusualExpenses(txns, 'USD', now);
      expect(a.single.focusKey, 'big');
      expect(a.single.compareAmount, const Money(2000, 'USD'));
      expect(a.single.date, DateTime(2026, 9, 21));
    });

    test('needs enough history and ignores older expenses', () {
      final List<Transaction> thin = <Transaction>[
        for (int i = 1; i <= 3; i++) tx(DateTime(2026, 8, i * 3), 'food', 20),
        tx(DateTime(2026, 9, 21), 'food', 90),
      ];
      expect(SmartAlertEngine.unusualExpenses(thin, 'USD', now), isEmpty);
      final List<Transaction> old = <Transaction>[
        for (int i = 1; i <= 5; i++) tx(DateTime(2026, 8, i), 'food', 20),
        tx(DateTime(2026, 9, 10), 'food', 90),
      ];
      expect(SmartAlertEngine.unusualExpenses(old, 'USD', now), isEmpty);
    });

    test('flags a category running well above its monthly norm', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 7, 10), 'fun', 100),
        tx(DateTime(2026, 8, 10), 'fun', 100),
        tx(DateTime(2026, 9, 5), 'fun', 90),
        tx(DateTime(2026, 9, 15), 'fun', 90),
      ];
      final List<AppAlert> a =
          SmartAlertEngine.categorySpikes(txns, 'USD', now);
      expect(a.single.kind, AlertKind.categorySpike);
      expect(a.single.amount, const Money(18000, 'USD'));
      expect(a.single.compareAmount, const Money(10000, 'USD'));
    });

    test('no spike without two earlier months of activity', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 8, 10), 'fun', 100),
        tx(DateTime(2026, 9, 5), 'fun', 400),
      ];
      expect(SmartAlertEngine.categorySpikes(txns, 'USD', now), isEmpty);
    });
  });

  group('summaries', () {
    test('weekly: last Monday–Sunday vs the week before', () {
      // Wednesday 23 Sep 2026 ⇒ last week is Mon 14 – Sun 20 Sep.
      final DateTime now = DateTime(2026, 9, 23);
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 9, 8), 'food', 100),
        tx(DateTime(2026, 9, 14), 'food', 60),
        tx(DateTime(2026, 9, 20), 'fun', 90),
        tx(DateTime(2026, 9, 21), 'fun', 500), // this week — excluded
      ];
      final AppAlert w = SmartAlertEngine.weeklyDigest(txns, 'USD', now)!;
      expect(w.date, DateTime(2026, 9, 14));
      expect(w.amount, const Money(15000, 'USD'));
      expect(w.compareAmount, const Money(10000, 'USD'));
      expect(w.subject, 'fun');
    });

    test('weekly: nothing when last week was empty', () {
      expect(
          SmartAlertEngine.weeklyDigest(
              <Transaction>[tx(DateTime(2026, 9, 1), 'food', 10)],
              'USD',
              DateTime(2026, 9, 23)),
          isNull);
    });

    test('monthly: previous month, shown only early in the new month', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2026, 9, 1), 'salary', 1000,
            type: TransactionType.income),
        tx(DateTime(2026, 9, 5), 'food', 300),
        tx(DateTime(2026, 9, 9), 'housing', 500),
      ];
      final AppAlert m =
          SmartAlertEngine.monthlyDigest(txns, 'USD', DateTime(2026, 10, 3))!;
      expect(m.date, DateTime(2026, 9, 1));
      expect(m.amount, const Money(80000, 'USD'));
      expect(m.compareAmount, const Money(100000, 'USD'));
      expect(m.ratio, closeTo(0.2, 1e-9));
      expect(m.subject, 'housing');
      expect(SmartAlertEngine.monthlyDigest(txns, 'USD', DateTime(2026, 10, 9)),
          isNull);
    });
  });

  test('other currencies are ignored, never converted', () {
    final List<AppAlert> a = SmartAlertEngine.build(
      transactions: <Transaction>[
        tx(DateTime(2026, 9, 14), 'food', 60, currency: 'EUR'),
      ],
      plannedThisMonth: const <String, int>{},
      currency: 'USD',
      now: DateTime(2026, 9, 23),
    );
    expect(a, isEmpty);
  });
}
