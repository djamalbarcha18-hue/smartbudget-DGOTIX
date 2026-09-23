import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// What one auto-post run should write: the transactions that fell due and the
/// rules with their `lastPosted` moved forward.
class PostingPlan {
  const PostingPlan({required this.transactions, required this.updatedRules});

  final List<Transaction> transactions;
  final List<RecurringRule> updatedRules;

  bool get isEmpty => transactions.isEmpty && updatedRules.isEmpty;
}

/// Pure schedule math for [RecurringRule]s (no Flutter, no IO).
///
/// Every date here is a calendar date (local midnight). The n-th occurrence is
/// computed from the rule's start, so month-end anchors never drift.
abstract final class RecurrenceEngine {
  /// Safety cap on occurrences posted per rule in one run. A long catch-up
  /// (e.g. a weekly rule started years ago) finishes over successive runs.
  static const int maxCatchUp = 120;

  static const String _idPrefix = 'rec-';

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// The [n]-th occurrence of [rule]; `n == 0` is the start date.
  static DateTime occurrence(RecurringRule rule, int n) {
    final DateTime s = rule.startDate;
    switch (rule.frequency) {
      case RecurrenceFrequency.weekly:
        return DateTime(s.year, s.month, s.day + 7 * n);
      case RecurrenceFrequency.monthly:
        final int m = s.month - 1 + n;
        final int year = s.year + m ~/ 12;
        final int month = m % 12 + 1;
        final int dim = daysInMonth(year, month);
        return DateTime(year, month, s.day > dim ? dim : s.day);
      case RecurrenceFrequency.yearly:
        final int year = s.year + n;
        final int dim = daysInMonth(year, s.month);
        return DateTime(year, s.month, s.day > dim ? dim : s.day);
    }
  }

  /// Occurrences that are due now: strictly after `lastPosted`, on or before
  /// today, oldest first, at most [maxCatchUp]. Paused rules have none.
  static List<DateTime> dueDates(RecurringRule rule, DateTime now) {
    if (!rule.active) return const <DateTime>[];
    final DateTime today = dateOnly(now);
    final DateTime last = dateOnly(rule.lastPosted);
    final List<DateTime> out = <DateTime>[];
    for (int n = 1;; n++) {
      final DateTime d = occurrence(rule, n);
      if (d.isAfter(today)) break;
      if (d.isAfter(last)) {
        out.add(d);
        if (out.length >= maxCatchUp) break;
      }
    }
    return out;
  }

  /// The first occurrence strictly after [after].
  static DateTime nextAfter(RecurringRule rule, DateTime after) {
    final DateTime a = dateOnly(after);
    for (int n = 0;; n++) {
      final DateTime d = occurrence(rule, n);
      if (d.isAfter(a)) return d;
    }
  }

  /// The next occurrence that has not been posted yet.
  static DateTime nextOccurrence(RecurringRule rule) =>
      nextAfter(rule, rule.lastPosted);

  /// The latest occurrence on or before [now], or null if the schedule hasn't
  /// started yet.
  static DateTime? lastOnOrBefore(RecurringRule rule, DateTime now) {
    final DateTime today = dateOnly(now);
    DateTime? last;
    for (int n = 0;; n++) {
      final DateTime d = occurrence(rule, n);
      if (d.isAfter(today)) return last;
      last = d;
    }
  }

  /// Resuming a paused rule skips the occurrences missed while it was paused:
  /// only dates after today are posted from then on.
  static RecurringRule resume(RecurringRule rule, DateTime now) {
    final DateTime? missed = lastOnOrBefore(rule, now);
    final DateTime last = (missed != null && missed.isAfter(rule.lastPosted))
        ? missed
        : rule.lastPosted;
    return rule.copyWith(active: true, lastPosted: last);
  }

  /// Stable id for the occurrence of [ruleId] on [date], so re-running a post
  /// (another tab, a retry) can never create duplicates.
  static String occurrenceId(String ruleId, DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$_idPrefix$ruleId-$y$m$d';
  }

  /// True for transactions created by a recurring rule.
  static bool isRecurring(Transaction t) => t.id.startsWith(_idPrefix);

  /// The transaction a rule posts on [date].
  static Transaction materialize(
    RecurringRule rule,
    DateTime date, {
    required DateTime createdAt,
  }) {
    return Transaction(
      id: occurrenceId(rule.id, date),
      date: dateOnly(date),
      type: rule.type,
      category: rule.category,
      amount: rule.amount,
      description: rule.description,
      paymentMethod: rule.paymentMethod,
      notes: rule.notes,
      createdAt: createdAt,
    );
  }

  /// Everything that is due across [rules] at [now].
  static PostingPlan plan(List<RecurringRule> rules, DateTime now) {
    final List<Transaction> txns = <Transaction>[];
    final List<RecurringRule> updated = <RecurringRule>[];
    for (final RecurringRule r in rules) {
      final List<DateTime> due = dueDates(r, now);
      if (due.isEmpty) continue;
      for (final DateTime d in due) {
        txns.add(materialize(r, d, createdAt: now));
      }
      updated.add(r.copyWith(lastPosted: due.last));
    }
    return PostingPlan(transactions: txns, updatedRules: updated);
  }

  /// A rule's amount expressed per month (weekly × 52 / 12, yearly / 12),
  /// rounded to the currency's minor unit.
  static Money monthlyEquivalent(RecurringRule rule) {
    final int minor = rule.amount.minorUnits;
    final int perMonth = switch (rule.frequency) {
      RecurrenceFrequency.weekly => (minor * 52 / 12).round(),
      RecurrenceFrequency.monthly => minor,
      RecurrenceFrequency.yearly => (minor / 12).round(),
    };
    return Money(perMonth, rule.amount.currencyCode);
  }

  /// Monthly total of the active rules of [type] in [currency] (rules in other
  /// currencies are left out rather than converted with a guessed rate).
  static Money monthlyTotal(
    List<RecurringRule> rules,
    TransactionType type,
    String currency,
  ) {
    int sum = 0;
    for (final RecurringRule r in rules) {
      if (!r.active || r.type != type) continue;
      if (r.amount.currencyCode != currency) continue;
      sum += monthlyEquivalent(r).minorUnits;
    }
    return Money(sum, currency);
  }
}
