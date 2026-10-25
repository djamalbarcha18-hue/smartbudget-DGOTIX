import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/reminders/domain/daily_reminder.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The daily reminder's settings, kept on this device.
final reminderProvider = NotifierProvider<ReminderController, ReminderSettings>(
    ReminderController.new);

class ReminderController extends Notifier<ReminderSettings> {
  static const String _onKey = 'sb_reminder_on';
  static const String _timeKey = 'sb_reminder_time';

  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> t = (prefs.getString(_timeKey) ?? '').split(':');
      state = state.copyWith(
        enabled: prefs.getBool(_onKey),
        hour: t.length == 2 ? int.tryParse(t[0]) : null,
        minute: t.length == 2 ? int.tryParse(t[1]) : null,
      );
    } catch (_) {
      // Keep the defaults.
    }
  }

  /// Turns the reminder on (asking for permission to notify) or off. Returns
  /// false when the phone doesn't allow notifications for the app.
  Future<bool> setEnabled(bool on) async {
    if (on && !await ReminderNotifications.instance.requestPermission()) {
      return false;
    }
    state = state.copyWith(enabled: on);
    await _save((SharedPreferences p) => p.setBool(_onKey, on));
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _save(
        (SharedPreferences p) => p.setString(_timeKey, state.timeLabel));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// What should be scheduled right now: the times and the text, in the app
/// language. Rebuilt when the settings, the language or the transactions
/// change; app.dart hands every new plan to [ReminderNotifications].
@immutable
class ReminderPlan {
  const ReminderPlan(this.times, this.title, this.body, this.channel);

  final List<DateTime> times;
  final String title;
  final String body;
  final String channel;

  @override
  bool operator ==(Object other) =>
      other is ReminderPlan &&
      listEquals(other.times, times) &&
      other.title == title &&
      other.body == body &&
      other.channel == channel;

  @override
  int get hashCode => Object.hash(Object.hashAll(times), title, body, channel);
}

final reminderPlanProvider = Provider<ReminderPlan?>((ref) {
  if (!ReminderNotifications.supported) return null;
  final ReminderSettings settings = ref.watch(reminderProvider);
  final List<Transaction>? txns = ref.watch(transactionsProvider).valueOrNull;
  // Until the transactions are read, don't plan around a day that may
  // already have entries.
  if (settings.enabled && txns == null) return null;
  final Locale locale = ref.watch(localeProvider);
  final AppLocalizations l = lookupAppLocalizations(locale);
  final DateTime now = DateTime.now();
  return ReminderPlan(
    DailyReminder.plan(
      now: now,
      settings: settings,
      loggedToday:
          DailyReminder.loggedToday(txns ?? const <Transaction>[], now),
    ),
    l.reminderNotifTitle,
    l.reminderNotifBody,
    l.reminderTitle,
  );
});

/// Applies a plan: schedules its times, or clears them when it has none.
Future<void> applyReminderPlan(ReminderPlan plan) {
  final ReminderNotifications n = ReminderNotifications.instance;
  return plan.times.isEmpty
      ? n.cancel()
      : n.schedule(plan.times,
          title: plan.title, body: plan.body, channel: plan.channel);
}
