import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/sadaqah/domain/sadaqah_commitment.dart';

/// The Sadaqah Planner's reminders, scheduled on the phone (Android app
/// only, like the daily reminder). Their text is neutral: no amount, no note,
/// and hidden on the lock screen.
abstract class SadaqahNotifications {
  static bool get supported => ReminderNotifications.supported;

  static SadaqahNotifications instance =
      supported ? _AndroidSadaqah() : _NoSadaqah();

  /// Replaces every planner reminder with one at each of [times].
  Future<void> schedule(List<DateTime> times,
      {required String title, required String body, required String channel});

  Future<void> cancel();
}

class _NoSadaqah extends SadaqahNotifications {
  @override
  Future<void> schedule(List<DateTime> times,
      {required String title,
      required String body,
      required String channel}) async {}
  @override
  Future<void> cancel() async {}
}

class _AndroidSadaqah extends SadaqahNotifications {
  /// The same plugin as the daily reminder (it is set up there once).
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// The daily reminder uses ids 1 to 14; the planner 200 and up.
  static const int _firstId = 200;

  static const String _payload = 'sadaqah';

  @override
  Future<void> schedule(List<DateTime> times,
      {required String title,
      required String body,
      required String channel}) async {
    await cancel();
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sadaqah_reminder',
        channel,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        visibility: NotificationVisibility.private,
      ),
    );
    int id = _firstId;
    for (final DateTime at in times.take(SadaqahSchedule.maxReminders)) {
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: _payload,
      );
    }
  }

  @override
  Future<void> cancel() async {
    await ReminderNotifications.instance.init();
    for (int id = _firstId;
        id < _firstId + SadaqahSchedule.maxReminders;
        id++) {
      await _plugin.cancel(id: id);
    }
  }
}
