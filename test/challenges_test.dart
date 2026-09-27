import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/challenges/domain/challenges.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

int _seq = 0;
Transaction tx(DateTime d, int minor,
        {TransactionType type = TransactionType.expense,
        String category = 'الطعام'}) =>
    Transaction(
      id: 't${_seq++}',
      date: d,
      type: type,
      category: category,
      amount: Money(minor, 'DZD'),
      createdAt: d,
    );

Challenge ch(ChallengeType t, DateTime start) =>
    Challenge(id: 'c', type: t, start: start, createdAt: start);

ChallengeProgress eval(Challenge c, List<Transaction> txns, DateTime now) =>
    ChallengeEngine.evaluate(c, txns, 'DZD', now);

void main() {
  final DateTime s = DateTime(2026, 9, 1);

  group('no eating out for 7 days', () {
    final Challenge c = ch(ChallengeType.noEatingOut7, s);

    test('clean days count up and it is won after day 7', () {
      final List<Transaction> t = <Transaction>[tx(DateTime(2026, 9, 3), 500)];
      final ChallengeProgress mid = eval(c, t, DateTime(2026, 9, 4, 18));
      expect(mid.status, ChallengeStatus.active);
      expect(mid.current, 4);
      expect(mid.daysLeft, 4);
      expect(eval(c, t, DateTime(2026, 9, 7, 23)).status, ChallengeStatus.active);
      expect(eval(c, t, DateTime(2026, 9, 8)).status, ChallengeStatus.won);
    });

    test('one restaurant expense in the window loses it', () {
      final List<Transaction> t = <Transaction>[
        tx(DateTime(2026, 9, 5), 1200, category: 'المطاعم'),
      ];
      expect(eval(c, t, DateTime(2026, 9, 6)).status, ChallengeStatus.lost);
      // Outside the window it doesn't count.
      expect(
          eval(c, <Transaction>[tx(DateTime(2026, 9, 9), 1200, category: 'المطاعم')],
                  DateTime(2026, 9, 10))
              .status,
          ChallengeStatus.won);
    });
  });

  group('3 spend-free days in a week', () {
    final Challenge c = ch(ChallengeType.noSpend3of7, s);
    test('won as soon as 3 finished days had no expense', () {
      final List<Transaction> t = <Transaction>[
        tx(DateTime(2026, 9, 1), 100),
        tx(DateTime(2026, 9, 3), 100),
      ];
      // Finished days 1..4: free on 2 and 4 → 2.
      expect(eval(c, t, DateTime(2026, 9, 5)).current, 2);
      expect(eval(c, t, DateTime(2026, 9, 5)).status, ChallengeStatus.active);
      expect(eval(c, t, DateTime(2026, 9, 6)).status, ChallengeStatus.won);
    });

    test('lost when the week ends short', () {
      final List<Transaction> t = <Transaction>[
        for (int d = 1; d <= 6; d++) tx(DateTime(2026, 9, d), 100),
      ];
      expect(eval(c, t, DateTime(2026, 9, 8)).status, ChallengeStatus.lost);
    });
  });

  group('log every day for 7 days', () {
    final Challenge c = ch(ChallengeType.logDaily7, s);
    test('today can still be logged; a missed past day loses', () {
      final List<Transaction> t = <Transaction>[
        tx(DateTime(2026, 9, 1), 100),
        tx(DateTime(2026, 9, 2), 100, type: TransactionType.income),
      ];
      expect(eval(c, t, DateTime(2026, 9, 3)).status, ChallengeStatus.active);
      expect(eval(c, t, DateTime(2026, 9, 4)).status, ChallengeStatus.lost);
    });

    test('won once all 7 days are logged', () {
      final List<Transaction> t = <Transaction>[
        for (int d = 1; d <= 7; d++) tx(DateTime(2026, 9, d), 100),
      ];
      expect(eval(c, t, DateTime(2026, 9, 7, 20)).status, ChallengeStatus.won);
    });
  });

  group('save 20% this month', () {
    final Challenge c = ch(ChallengeType.save20Month, DateTime(2026, 9, 10));
    final List<Transaction> t = <Transaction>[
      tx(DateTime(2026, 9, 1), 100000, type: TransactionType.income),
      tx(DateTime(2026, 9, 12), 75000),
    ];
    test('tracks the month\'s rate and decides at month end', () {
      expect(c.end, DateTime(2026, 9, 30));
      final ChallengeProgress mid = eval(c, t, DateTime(2026, 9, 20));
      expect(mid.status, ChallengeStatus.active);
      expect(mid.current, 25);
      expect(eval(c, t, DateTime(2026, 10, 1)).status, ChallengeStatus.won);
      expect(
          eval(c, <Transaction>[...t, tx(DateTime(2026, 9, 25), 10000)],
                  DateTime(2026, 10, 1))
              .status,
          ChallengeStatus.lost);
    });
  });

  group('streaks', () {
    final List<Transaction> t = <Transaction>[
      for (int d = 1; d <= 5; d++) tx(DateTime(2026, 9, d), 100),
      for (int d = 10; d <= 12; d++) tx(DateTime(2026, 9, d), 100),
    ];
    test('current streak runs to today, or yesterday before today\'s entry', () {
      expect(Streaks.current(t, DateTime(2026, 9, 12, 9)), 3);
      expect(Streaks.current(t, DateTime(2026, 9, 13, 9)), 3);
      expect(Streaks.current(t, DateTime(2026, 9, 14)), 0);
    });
    test('longest streak', () => expect(Streaks.longest(t), 5));
    test('spend-free days this month (finished days only)', () {
      expect(Streaks.noSpendDaysThisMonth(t, DateTime(2026, 9, 13)), 4);
    });
  });

  group('badges', () {
    test('earned only from real data', () {
      final DateTime now = DateTime(2026, 10, 5);
      final List<Transaction> t = <Transaction>[
        for (int d = 1; d <= 8; d++) tx(DateTime(2026, 9, d), 1000),
        tx(DateTime(2026, 9, 1), 100000, type: TransactionType.income),
      ];
      final Set<BadgeKind> b = Badges.earned(
        txns: t,
        currency: 'DZD',
        now: now,
        budgets: <BudgetTarget>[
          BudgetTarget(
            id: 'b',
            year: 2026,
            month: 9,
            category: 'الطعام',
            planned: const Money(10000, 'DZD'),
            createdAt: DateTime(2026, 9),
          ),
        ],
      );
      expect(
          b,
          containsAll(<BadgeKind>[
            BadgeKind.firstEntry,
            BadgeKind.streak7,
            BadgeKind.saver20,
            BadgeKind.budgetKept,
          ]));
      expect(b, isNot(contains(BadgeKind.streak30)));
      expect(b, isNot(contains(BadgeKind.goalReached)));
      expect(Badges.earned(txns: const <Transaction>[], currency: 'DZD', now: now),
          isEmpty);
    });
  });
}
