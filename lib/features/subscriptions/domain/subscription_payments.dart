import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Charge dates waiting for the user's answer ("was it charged?"), and the
/// expenses that may already be that charge (pure: no Flutter, no IO).
///
/// Nothing is recorded on its own: a subscription may have been cancelled,
/// or charged a different amount, and only the user knows.
abstract final class SubscriptionPayments {
  /// At most this many past charges wait at once (a long absence).
  static const int maxWaiting = 12;

  /// How close an expense must be to count as the charge: within three days,
  /// and within a tenth of the amount (exchange fees, taxes).
  static const int dayWindow = 3;
  static const double amountTolerance = 0.10;

  /// The charges of [rule] from its first one on, not yet answered
  /// (after `lastPosted`) and not in the future, oldest first.
  ///
  /// Unlike ordinary recurring rules, the first charge counts too: a
  /// subscription's rule starts on its next charge.
  static List<DateTime> due(RecurringRule rule, DateTime now) {
    if (!rule.active) return const <DateTime>[];
    final DateTime today = RecurrenceEngine.dateOnly(now);
    final DateTime last = RecurrenceEngine.dateOnly(rule.lastPosted);
    final List<DateTime> out = <DateTime>[];
    for (int n = 0;; n++) {
      final DateTime d = RecurrenceEngine.occurrence(rule, n);
      if (d.isAfter(today)) break;
      if (d.isAfter(last)) {
        out.add(d);
        if (out.length >= maxWaiting) break;
      }
    }
    return out;
  }

  /// The key a charge is filed under in Subscription.payments.
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Expenses in [txns] that may be the charge of [rule] on [charge]: same
  /// currency, amount within [amountTolerance], date within [dayWindow]
  /// days, and not already the record of another charge ([linked] ids).
  /// Closest date first, then closest amount.
  static List<Transaction> candidates(
    RecurringRule rule,
    DateTime charge,
    Iterable<Transaction> txns, {
    Set<String> linked = const <String>{},
  }) {
    final DateTime day = RecurrenceEngine.dateOnly(charge);
    final int want = rule.amount.minorUnits;
    final int slack = (want * amountTolerance).round();
    // Calendar days (UTC, so a clock change can't shave an hour off).
    final DateTime d0 = DateTime.utc(day.year, day.month, day.day);
    int daysOff(Transaction t) =>
        DateTime.utc(t.date.year, t.date.month, t.date.day)
            .difference(d0)
            .inDays
            .abs();
    final List<Transaction> out = <Transaction>[
      for (final Transaction t in txns)
        if (t.type == TransactionType.expense &&
            t.amount.currencyCode == rule.amount.currencyCode &&
            (t.amount.minorUnits - want).abs() <= slack &&
            daysOff(t) <= dayWindow &&
            !linked.contains(t.id) &&
            t.id != RecurrenceEngine.occurrenceId(rule.id, day))
          t,
    ];
    out.sort((Transaction a, Transaction b) {
      final int d = daysOff(a).compareTo(daysOff(b));
      if (d != 0) return d;
      return (a.amount.minorUnits - want)
          .abs()
          .compareTo((b.amount.minorUnits - want).abs());
    });
    return out;
  }

  /// Every transaction id already filed as a charge in [subs].
  static Set<String> linkedIds(Iterable<Subscription> subs) => <String>{
        for (final Subscription s in subs) ...s.payments.values,
      };
}
