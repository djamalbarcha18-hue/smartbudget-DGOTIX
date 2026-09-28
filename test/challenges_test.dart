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

Transaction side(DateTime d, int minor) => tx(d, minor, category: 'المطاعم');

Challenge ch(int days, DateTime start,
        {Set<String> cats = SideFree.defaultCategories}) =>
    Challenge(
        id: 'c', days: days, categories: cats, start: start, createdAt: start);

ChallengeProgress eval(Challenge c, List<Transaction> txns, DateTime now) =>
    ChallengeEngine.evaluate(c, txns, 'DZD', now);

void main() {
  final DateTime s = DateTime(2026, 9, 1);

  group('days without side spending', () {
    test('essentials never break it; the strip shows each day', () {
      final ChallengeProgress p = eval(
        ch(7, s),
        <Transaction>[
          tx(DateTime(2026, 9, 2), 5000), // groceries: fine
          tx(DateTime(2026, 9, 3), 90000, category: 'السكن'),
        ],
        DateTime(2026, 9, 4, 12),
      );
      expect(p.status, ChallengeStatus.active);
      expect(p.clean, 3);
      expect(p.marks, <DayMark>[
        DayMark.clean,
        DayMark.clean,
        DayMark.clean,
        DayMark.today,
        DayMark.upcoming,
        DayMark.upcoming,
        DayMark.upcoming,
      ]);
      expect(p.daysLeft, 4);
    });

    test('a 7-day run forgives one slip, not two', () {
      final Challenge c = ch(7, s);
      final List<Transaction> one = <Transaction>[side(DateTime(2026, 9, 3), 800)];
      final ChallengeProgress won = eval(c, one, DateTime(2026, 9, 8));
      expect(won.status, ChallengeStatus.won);
      expect(won.clean, 6);
      expect(won.slips, 1);
      expect(won.sideSpent, const Money(800, 'DZD'));

      final ChallengeProgress lost = eval(
          c,
          <Transaction>[...one, side(DateTime(2026, 9, 5), 500)],
          DateTime(2026, 9, 5, 20));
      expect(lost.status, ChallengeStatus.lost);
    });

    test('3 days allow no slip; a slip today counts right away', () {
      final ChallengeProgress p = eval(ch(3, s),
          <Transaction>[side(DateTime(2026, 9, 2, 9), 300)], DateTime(2026, 9, 2, 10));
      expect(p.status, ChallengeStatus.lost);
      expect(p.marks[1], DayMark.slip);
    });

    test('only the chosen categories count', () {
      final ChallengeProgress p = eval(
          ch(3, s, cats: const <String>{'التسوق'}),
          <Transaction>[side(DateTime(2026, 9, 2), 300)],
          DateTime(2026, 9, 4));
      expect(p.status, ChallengeStatus.won);
      expect(p.clean, 3);
    });

    test('estimates money kept from the weeks before', () {
      // 28 days before: 2 800 DZD on extras → 100 a day on average.
      final List<Transaction> t = <Transaction>[
        for (int i = 1; i <= 28; i++)
          side(s.subtract(Duration(days: i)), 10000),
        side(DateTime(2026, 9, 2), 5000),
      ];
      final ChallengeProgress p = eval(ch(7, s), t, DateTime(2026, 9, 8));
      // 7 days × 100.00 − 50.00 spent.
      expect(p.saved, const Money(65000, 'DZD'));
      // No history → no estimate.
      expect(eval(ch(7, s), const <Transaction>[], DateTime(2026, 9, 8)).saved,
          isNull);
      // Day one isn't over yet → no estimate.
      expect(eval(ch(7, s), t, DateTime(2026, 9, 1, 20)).saved, isNull);
    });

    test('old challenges load as the nearest side-free one', () {
      final Challenge c = Challenge.fromJson(<String, dynamic>{
        'id': 'x',
        'type': 'noEatingOut7',
        'start': '2026-09-01',
        'createdAt': '2026-09-01T10:00:00.000',
      });
      expect(c.days, 7);
      expect(c.categories, <String>{'المطاعم'});
      final Challenge round = Challenge.fromJson(ch(14, s).toJson());
      expect(round.days, 14);
      expect(round.categories, SideFree.defaultCategories);
      expect(round.end, DateTime(2026, 9, 14));
    });

    test('allowed slips grow by week', () {
      expect(SideFree.durations.map(SideFree.allowedSlips).toList(),
          <int>[0, 1, 2, 4]);
    });
  });

  group('clean-day streaks', () {
    final List<Transaction> t = <Transaction>[
      tx(DateTime(2026, 9, 1), 100), // tracking starts
      side(DateTime(2026, 9, 5), 100),
      side(DateTime(2026, 9, 10), 100),
    ];
    const Set<String> cats = SideFree.defaultCategories;

    test('current run ends yesterday and never goes before tracking', () {
      expect(SideFreeStreaks.current(t, cats, DateTime(2026, 9, 14)), 3);
      expect(SideFreeStreaks.current(t, cats, DateTime(2026, 9, 11)), 0);
      expect(SideFreeStreaks.current(t, cats, DateTime(2026, 9, 3)), 2);
    });

    test('longest run and this month', () {
      expect(SideFreeStreaks.longest(t, cats, DateTime(2026, 9, 14)), 4);
      expect(SideFreeStreaks.thisMonth(t, cats, DateTime(2026, 9, 14)), 11);
      expect(SideFreeStreaks.current(const <Transaction>[], cats,
          DateTime(2026, 9, 14)), 0);
    });
  });

  group('badges', () {
    test('earned only from real data', () {
      final DateTime now = DateTime(2026, 10, 5);
      final List<Transaction> t = <Transaction>[
        for (int d = 1; d <= 8; d++) tx(DateTime(2026, 9, d), 1000),
        side(DateTime(2026, 9, 20), 500),
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
            BadgeKind.cleanWeek,
            BadgeKind.saver20,
            BadgeKind.budgetKept,
          ]));
      expect(b, isNot(contains(BadgeKind.cleanMonth)));
      expect(b, isNot(contains(BadgeKind.goalReached)));
      expect(Badges.earned(txns: const <Transaction>[], currency: 'DZD', now: now),
          isEmpty);
    });
  });
}
