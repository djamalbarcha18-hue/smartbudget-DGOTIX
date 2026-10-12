import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/notifications/domain/notification_feed.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// A quarterly performance bonus ("مردودية"), by default of variable amount.
RecurringRule bonus({
  RecurrenceFrequency frequency = RecurrenceFrequency.quarterly,
  required DateTime start,
  DateTime? lastPosted,
  bool variable = true,
  bool active = true,
  int minor = 3000000,
  String id = 'rule-bonus',
}) =>
    RecurringRule(
      id: id,
      type: TransactionType.income,
      category: 'مكافآت وحوافز',
      amount: Money(minor, 'DZD'),
      description: 'مردودية',
      frequency: frequency,
      startDate: start,
      lastPosted: lastPosted ?? start,
      active: active,
      variableAmount: variable,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('every 3 and 6 months', () {
    test('quarterly steps three months and clamps month ends', () {
      final RecurringRule r = bonus(start: DateTime(2026, 1, 31));
      expect(RecurrenceEngine.occurrence(r, 1), DateTime(2026, 4, 30));
      expect(RecurrenceEngine.occurrence(r, 2), DateTime(2026, 7, 31));
      expect(RecurrenceEngine.occurrence(r, 4), DateTime(2027, 1, 31));
    });

    test('half-yearly steps six months across the year', () {
      final RecurringRule r = bonus(
          frequency: RecurrenceFrequency.halfYearly,
          start: DateTime(2026, 8, 31));
      expect(RecurrenceEngine.occurrence(r, 1), DateTime(2027, 2, 28));
      expect(RecurrenceEngine.occurrence(r, 2), DateTime(2027, 8, 31));
    });

    test('monthly equivalents divide by 3 and 6', () {
      expect(
          RecurrenceEngine.monthlyEquivalent(
                  bonus(start: DateTime(2026, 1, 1), minor: 900))
              .minorUnits,
          300);
      expect(
          RecurrenceEngine.monthlyEquivalent(bonus(
                  frequency: RecurrenceFrequency.halfYearly,
                  start: DateTime(2026, 1, 1),
                  minor: 900))
              .minorUnits,
          150);
    });

    test('a fixed quarterly rule is posted on its own', () {
      final RecurringRule r =
          bonus(start: DateTime(2026, 1, 15), variable: false);
      final PostingPlan p =
          RecurrenceEngine.plan(<RecurringRule>[r], DateTime(2026, 7, 20));
      expect(p.transactions.map((Transaction t) => t.date),
          <DateTime>[DateTime(2026, 4, 15), DateTime(2026, 7, 15)]);
    });
  });

  group('variable amount', () {
    test('is never posted on its own', () {
      final RecurringRule r = bonus(start: DateTime(2026, 1, 15));
      final PostingPlan p =
          RecurrenceEngine.plan(<RecurringRule>[r], DateTime(2026, 7, 20));
      expect(p.isEmpty, isTrue);
    });

    test('waits for the real amount, oldest first, one per rule', () {
      final RecurringRule r = bonus(start: DateTime(2026, 1, 15));
      final List<PendingOccurrence> w = RecurrenceEngine.awaitingAmount(
          <RecurringRule>[r], DateTime(2026, 7, 20));
      expect(w, hasLength(1));
      expect(w.single.date, DateTime(2026, 4, 15));
      expect(w.single.more, 1);
      // Nothing waits before the first due date, nor while paused.
      expect(
          RecurrenceEngine.awaitingAmount(
              <RecurringRule>[r], DateTime(2026, 4, 14)),
          isEmpty);
      expect(
          RecurrenceEngine.awaitingAmount(<RecurringRule>[
            bonus(start: DateTime(2026, 1, 15), active: false)
          ], DateTime(2026, 7, 20)),
          isEmpty);
    });

    test('once confirmed or skipped, the next one waits', () {
      final RecurringRule r = bonus(
          start: DateTime(2026, 1, 15), lastPosted: DateTime(2026, 4, 15));
      final List<PendingOccurrence> w = RecurrenceEngine.awaitingAmount(
          <RecurringRule>[r], DateTime(2026, 7, 20));
      expect(w.single.date, DateTime(2026, 7, 15));
      expect(w.single.more, 0);
    });

    test('is left out of the fixed monthly totals and counted as expected', () {
      final List<RecurringRule> rules = <RecurringRule>[
        bonus(start: DateTime(2026, 1, 1), minor: 900),
        bonus(
            id: 'salary',
            frequency: RecurrenceFrequency.monthly,
            start: DateTime(2026, 1, 1),
            variable: false,
            minor: 5000),
      ];
      expect(
          RecurrenceEngine.monthlyTotal(rules, TransactionType.income, 'DZD')
              .minorUnits,
          5000);
      expect(
          RecurrenceEngine.monthlyTotal(rules, TransactionType.income, 'DZD',
                  variable: true)
              .minorUnits,
          300);
    });

    test('survives a backup or sync round trip', () {
      final RecurringRule r = bonus(start: DateTime(2026, 1, 15));
      final RecurringRule back = RecurringRule.fromJson(r.toJson());
      expect(back.variableAmount, isTrue);
      expect(back.frequency, RecurrenceFrequency.quarterly);
      // Fixed rules keep the old shape (no new key).
      expect(bonus(start: DateTime(2026, 1, 15), variable: false).toJson(),
          isNot(contains('variableAmount')));
    });

    test('raises a "enter the amount" notification instead of "upcoming"', () {
      final RecurringRule r = bonus(start: DateTime(2026, 1, 15));
      final DateTime now = DateTime(2026, 4, 16);
      final List<AppAlert> waiting =
          NotificationFeed.awaitingAmount(<RecurringRule>[r], now);
      expect(waiting.single.kind, AlertKind.recurringConfirm);
      expect(waiting.single.route, '/recurring');
      expect(
          NotificationFeed.upcomingRecurring(<RecurringRule>[r], now), isEmpty);
    });
  });
}
