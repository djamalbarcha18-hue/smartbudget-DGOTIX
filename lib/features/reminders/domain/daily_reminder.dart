import 'package:flutter/foundation.dart';

import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The daily reminder's settings: off until the user turns it on, 9 pm by
/// default.
@immutable
class ReminderSettings {
  const ReminderSettings(
      {this.enabled = false, this.hour = 21, this.minute = 0});

  final bool enabled;
  final int hour;
  final int minute;

  /// "21:00", Latin digits.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}

/// When the reminder fires: at the chosen time on each of the coming days,
/// skipping today once something has been recorded today (or the time has
/// passed). A week is scheduled ahead, so it keeps coming while the app
/// stays closed; opening the app or recording anything plans it again.
abstract final class DailyReminder {
  static const int daysAhead = 7;

  /// Whether the user recorded anything today. Entries posted on their own
  /// by a recurring rule (salary, rent…) don't count: they aren't a sign the
  /// day's spending was written down.
  static bool loggedToday(Iterable<Transaction> txns, DateTime now) =>
      txns.any((Transaction t) {
        if (RecurrenceEngine.isRecurring(t)) return false;
        final DateTime c = t.createdAt.toLocal();
        return c.year == now.year && c.month == now.month && c.day == now.day;
      });

  /// The coming reminder times, in device time.
  static List<DateTime> plan({
    required DateTime now,
    required ReminderSettings settings,
    required bool loggedToday,
    int days = daysAhead,
  }) {
    if (!settings.enabled) return const <DateTime>[];
    DateTime on(int day) => DateTime(
        now.year, now.month, now.day + day, settings.hour, settings.minute);
    final int first = !loggedToday && on(0).isAfter(now) ? 0 : 1;
    return <DateTime>[for (int d = first; d < first + days; d++) on(d)];
  }
}
