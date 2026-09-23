import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';

/// One entry in the notifications bell: an alert plus the stable id used to
/// remember whether the user has already seen it.
class FeedItem {
  const FeedItem({required this.id, required this.alert});
  final String id;
  final AppAlert alert;
}

/// Pure logic behind the notifications bell (no Flutter, no IO).
///
/// Notifications "renew": each id carries the period it belongs to, so a
/// situation that still holds next month (an over-budget category, an urgent
/// goal) notifies again, and every recurring occurrence is its own
/// notification. Seen ids are kept only while their alert is still active, so
/// a problem that goes away and later comes back is new again.
abstract final class NotificationFeed {
  /// How far ahead recurring items are announced.
  static const int upcomingDays = 3;

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String periodKey(DateTime now) => '${now.year}-${_two(now.month)}';

  static String _dayKey(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}';

  /// Stable id of [a] as seen at [now].
  static String idFor(AppAlert a, DateTime now) {
    switch (a.kind) {
      case AlertKind.recurringUpcoming:
        final DateTime d = a.date ?? now;
        return 'recurringUpcoming:${a.focusKey}@${_dayKey(d)}';
      case AlertKind.backupDue:
        return 'backupDue@${periodKey(now)}';
      case AlertKind.unusualExpense:
        return 'unusualExpense:${a.focusKey}';
      case AlertKind.weeklyDigest:
        return 'weeklyDigest@${_dayKey(a.date ?? now)}';
      case AlertKind.monthlyDigest:
        return 'monthlyDigest@${periodKey(a.date ?? now)}';
      case AlertKind.budgetForecast:
      case AlertKind.categorySpike:
      case AlertKind.budgetOver:
      case AlertKind.budgetNear:
      case AlertKind.netNegative:
      case AlertKind.savingsLow:
      case AlertKind.goalOverdue:
      case AlertKind.goalUrgent:
        final String subject = a.focusKey.isNotEmpty ? a.focusKey : a.subject;
        return '${a.kind.name}:$subject@${periodKey(now)}';
    }
  }

  /// Active recurring rules whose next unposted occurrence falls after today
  /// and within [upcomingDays] days.
  static List<AppAlert> upcomingRecurring(
    List<RecurringRule> rules,
    DateTime now,
  ) {
    final DateTime today = RecurrenceEngine.dateOnly(now);
    final DateTime limit = DateTime(today.year, today.month, today.day + upcomingDays);
    final List<AppAlert> out = <AppAlert>[];
    for (final RecurringRule r in rules) {
      if (!r.active) continue;
      final DateTime last = RecurrenceEngine.dateOnly(r.lastPosted);
      final DateTime next =
          RecurrenceEngine.nextAfter(r, last.isAfter(today) ? last : today);
      if (next.isAfter(limit)) continue;
      out.add(AppAlert(
        kind: AlertKind.recurringUpcoming,
        severity: AlertSeverity.info,
        subject: r.description.isEmpty ? r.category : r.description,
        amount: r.amount,
        route: '/recurring',
        focusKey: r.id,
        date: next,
      ));
    }
    out.sort((AppAlert a, AppAlert b) => a.date!.compareTo(b.date!));
    return out;
  }

  /// The backup reminder as a notification.
  static AppAlert backupAlert(String currency) => AppAlert(
        kind: AlertKind.backupDue,
        severity: AlertSeverity.info,
        subject: '',
        amount: Money.zero(currency),
        route: '/settings',
      );

  /// Merges every source into one list, most urgent first, without
  /// duplicate ids.
  static List<FeedItem> build({
    required List<AppAlert> finance,
    required List<AppAlert> upcoming,
    required bool backupDue,
    required String currency,
    required DateTime now,
    List<AppAlert> smart = const <AppAlert>[],
  }) {
    final List<AppAlert> all = <AppAlert>[
      ...finance,
      ...smart,
      ...upcoming,
      if (backupDue) backupAlert(currency),
    ];
    final Set<String> ids = <String>{};
    final List<FeedItem> out = <FeedItem>[];
    for (final AppAlert a in all) {
      final String id = idFor(a, now);
      if (ids.add(id)) out.add(FeedItem(id: id, alert: a));
    }
    // Stable sort by severity (keeps each source's own order within a level).
    final List<FeedItem> sorted = <FeedItem>[
      for (final AlertSeverity s in AlertSeverity.values)
        ...out.where((FeedItem f) => f.alert.severity == s),
    ];
    return sorted;
  }

  /// Ids in [items] the user hasn't seen yet.
  static Set<String> unread(List<FeedItem> items, Set<String> seen) =>
      <String>{
        for (final FeedItem f in items)
          if (!seen.contains(f.id)) f.id,
      };
}
