import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The expense category subscriptions are recorded in (already in the app).
const String subscriptionCategory = 'الاشتراكات';

/// Date math for subscriptions (pure: no Flutter, no IO). Every date is a
/// calendar day.
abstract final class SubscriptionSchedule {
  /// The rule holding the money and schedule of a subscription whose next
  /// charge is [nextCharge] (the end of a free trial for one in trial).
  ///
  /// The next charge is the rule's start, the anchor every later date is
  /// counted from, so "the 31st" stays the 31st (or the month's last day).
  /// `lastPosted` is the day before, so nothing earlier ever counts.
  /// It always asks before recording anything ([RecurringRule.variableAmount],
  /// which older app versions also respect): a subscription may have been
  /// cancelled, and only the user knows whether it was charged.
  static RecurringRule ruleFor({
    required String id,
    required String provider,
    required Money amount,
    required RecurrenceFrequency frequency,
    required DateTime nextCharge,
    required DateTime createdAt,
    String? walletId,
    String? notes,
  }) {
    final DateTime start = RecurrenceEngine.dateOnly(nextCharge);
    return RecurringRule(
      id: id,
      type: TransactionType.expense,
      category: subscriptionCategory,
      amount: amount,
      description: provider,
      notes: notes,
      walletId: walletId,
      frequency: frequency,
      startDate: start,
      lastPosted: DateTime(start.year, start.month, start.day - 1),
      variableAmount: true,
      createdAt: createdAt,
    );
  }

  /// The next charge of [rule] from [now] on: the first date not yet
  /// recorded, today included.
  static DateTime nextCharge(RecurringRule rule, DateTime now) {
    final DateTime today = RecurrenceEngine.dateOnly(now);
    DateTime d = RecurrenceEngine.nextOccurrence(rule);
    while (d.isBefore(today)) {
      d = RecurrenceEngine.nextAfter(rule, d);
    }
    return d;
  }

  /// The next [count] charges of [rule] from [now] on.
  static List<DateTime> upcoming(RecurringRule rule, DateTime now,
      {int count = 3}) {
    final List<DateTime> out = <DateTime>[];
    DateTime d = nextCharge(rule, now);
    while (out.length < count) {
      out.add(d);
      d = RecurrenceEngine.nextAfter(rule, d);
    }
    return out;
  }

  /// The days the user is reminded on before the next charge of [s], from
  /// today on, soonest first: the trial's own days while in trial, else the
  /// cycle's. Empty when reminders are off or it is no longer charged.
  static List<DateTime> reminderDays(
      Subscription s, RecurringRule rule, DateTime now) {
    if (!s.remindersOn || s.isOver) return const <DateTime>[];
    final DateTime today = RecurrenceEngine.dateOnly(now);
    final DateTime charge = nextCharge(rule, now);
    final List<int> before = s.trialEndsOn(charge)
        ? SubscriptionReminders.trialDays
        : SubscriptionReminders.daysFor(s, rule.frequency);
    final List<DateTime> out = <DateTime>[
      for (final int n in before)
        DateTime(charge.year, charge.month, charge.day - n),
    ]
      ..removeWhere((DateTime d) => d.isBefore(today))
      ..sort();
    return out;
  }

  /// Whether [day] can be the next charge: today or later.
  static bool validNextCharge(DateTime day, DateTime now) =>
      !RecurrenceEngine.dateOnly(day).isBefore(RecurrenceEngine.dateOnly(now));
}
