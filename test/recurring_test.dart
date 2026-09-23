import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

RecurringRule rule({
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  required DateTime start,
  DateTime? lastPosted,
  bool active = true,
  TransactionType type = TransactionType.expense,
  int minor = 50000,
  String currency = 'USD',
  String id = 'rule-a',
}) {
  return RecurringRule(
    id: id,
    type: type,
    category: 'السكن',
    amount: Money(minor, currency),
    description: 'Rent',
    frequency: frequency,
    startDate: start,
    lastPosted: lastPosted ?? start,
    active: active,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('schedule', () {
    test('monthly on the 31st clamps to short months without drifting', () {
      final RecurringRule r = rule(start: DateTime(2026, 1, 31));
      expect(RecurrenceEngine.occurrence(r, 1), DateTime(2026, 2, 28));
      expect(RecurrenceEngine.occurrence(r, 2), DateTime(2026, 3, 31));
      expect(RecurrenceEngine.occurrence(r, 3), DateTime(2026, 4, 30));
      expect(RecurrenceEngine.occurrence(r, 12), DateTime(2027, 1, 31));
      expect(RecurrenceEngine.occurrence(r, 25), DateTime(2028, 2, 29));
    });

    test('yearly on 29 Feb falls back to 28 Feb outside leap years', () {
      final RecurringRule r = rule(
          frequency: RecurrenceFrequency.yearly, start: DateTime(2028, 2, 29));
      expect(RecurrenceEngine.occurrence(r, 1), DateTime(2029, 2, 28));
      expect(RecurrenceEngine.occurrence(r, 4), DateTime(2032, 2, 29));
    });

    test('weekly steps by calendar days across month ends', () {
      final RecurringRule r = rule(
          frequency: RecurrenceFrequency.weekly, start: DateTime(2026, 3, 26));
      expect(RecurrenceEngine.occurrence(r, 1), DateTime(2026, 4, 2));
      expect(RecurrenceEngine.occurrence(r, 5), DateTime(2026, 4, 30));
    });

    test('next occurrence is the first one after the last posted', () {
      final RecurringRule r = rule(
          start: DateTime(2026, 1, 15), lastPosted: DateTime(2026, 9, 15));
      expect(RecurrenceEngine.nextOccurrence(r), DateTime(2026, 10, 15));
    });
  });

  group('due dates', () {
    test('everything after lastPosted up to and including today', () {
      final RecurringRule r = rule(start: DateTime(2026, 6, 23));
      expect(RecurrenceEngine.dueDates(r, DateTime(2026, 9, 23, 8)), <DateTime>[
        DateTime(2026, 7, 23),
        DateTime(2026, 8, 23),
        DateTime(2026, 9, 23),
      ]);
    });

    test('nothing before the next date, when paused, or when not started', () {
      final DateTime now = DateTime(2026, 9, 23);
      expect(RecurrenceEngine.dueDates(rule(start: DateTime(2026, 9, 1)), now),
          isEmpty);
      expect(
          RecurrenceEngine.dueDates(
              rule(start: DateTime(2026, 6, 1), active: false), now),
          isEmpty);
      expect(RecurrenceEngine.dueDates(rule(start: DateTime(2026, 12, 1)), now),
          isEmpty);
    });

    test('a long catch-up is capped per run and finishes on later runs', () {
      RecurringRule r = rule(
          frequency: RecurrenceFrequency.weekly, start: DateTime(2020, 1, 6));
      final DateTime now = DateTime(2026, 9, 23);
      int total = 0;
      for (int run = 0; run < 10; run++) {
        final PostingPlan p = RecurrenceEngine.plan(<RecurringRule>[r], now);
        if (p.isEmpty) break;
        expect(p.transactions.length,
            lessThanOrEqualTo(RecurrenceEngine.maxCatchUp));
        total += p.transactions.length;
        r = p.updatedRules.single;
      }
      // 6 Jan 2020 → 21 Sep 2026 is 350 weeks after the start.
      expect(total, 350);
      expect(r.lastPosted, DateTime(2026, 9, 21));
    });
  });

  group('posting plan', () {
    test('posts stable-id transactions and advances lastPosted', () {
      final DateTime now = DateTime(2026, 9, 23, 10);
      final RecurringRule r = rule(start: DateTime(2026, 7, 1));
      final PostingPlan p = RecurrenceEngine.plan(<RecurringRule>[r], now);
      expect(p.transactions.map((Transaction t) => t.id), <String>[
        'rec-rule-a-20260801',
        'rec-rule-a-20260901',
      ]);
      final Transaction t = p.transactions.first;
      expect(t.amount, const Money(50000, 'USD'));
      expect(t.category, 'السكن');
      expect(t.type, TransactionType.expense);
      expect(RecurrenceEngine.isRecurring(t), isTrue);
      expect(p.updatedRules.single.lastPosted, DateTime(2026, 9, 1));

      // Running again with the updated rule posts nothing (idempotent).
      expect(RecurrenceEngine.plan(p.updatedRules, now).isEmpty, isTrue);
    });

    test('resuming skips occurrences missed while paused', () {
      final RecurringRule paused = rule(
        start: DateTime(2026, 1, 10),
        lastPosted: DateTime(2026, 5, 10),
        active: false,
      );
      final RecurringRule resumed =
          RecurrenceEngine.resume(paused, DateTime(2026, 9, 23));
      expect(resumed.active, isTrue);
      expect(resumed.lastPosted, DateTime(2026, 9, 10));
      expect(RecurrenceEngine.dueDates(resumed, DateTime(2026, 9, 23)), isEmpty);
      expect(RecurrenceEngine.nextOccurrence(resumed), DateTime(2026, 10, 10));
    });
  });

  group('monthly totals', () {
    test('weekly and yearly are converted to a monthly equivalent', () {
      expect(
          RecurrenceEngine.monthlyEquivalent(rule(
              frequency: RecurrenceFrequency.weekly,
              start: DateTime(2026, 1, 1),
              minor: 10000)),
          const Money(43333, 'USD'));
      expect(
          RecurrenceEngine.monthlyEquivalent(rule(
              frequency: RecurrenceFrequency.yearly,
              start: DateTime(2026, 1, 1),
              minor: 120000)),
          const Money(10000, 'USD'));
    });

    test('only active rules of the type and currency are summed', () {
      final List<RecurringRule> rules = <RecurringRule>[
        rule(id: 'a', start: DateTime(2026, 1, 1), minor: 50000),
        rule(id: 'b', start: DateTime(2026, 1, 1), minor: 2000, active: false),
        rule(
            id: 'c',
            start: DateTime(2026, 1, 1),
            minor: 300000,
            type: TransactionType.income),
        rule(id: 'd', start: DateTime(2026, 1, 1), minor: 9900, currency: 'EUR'),
      ];
      expect(
          RecurrenceEngine.monthlyTotal(rules, TransactionType.expense, 'USD'),
          const Money(50000, 'USD'));
      expect(
          RecurrenceEngine.monthlyTotal(rules, TransactionType.income, 'USD'),
          const Money(300000, 'USD'));
    });
  });

  test('rule JSON round-trips', () {
    final RecurringRule r = rule(
      frequency: RecurrenceFrequency.weekly,
      start: DateTime(2026, 3, 2),
      lastPosted: DateTime(2026, 9, 21),
      active: false,
    );
    final RecurringRule back = RecurringRule.fromJson(r.toJson());
    expect(back.id, r.id);
    expect(back.frequency, RecurrenceFrequency.weekly);
    expect(back.amount, r.amount);
    expect(back.startDate, r.startDate);
    expect(back.lastPosted, r.lastPosted);
    expect(back.active, isFalse);
    expect(back.description, 'Rent');
  });
}
