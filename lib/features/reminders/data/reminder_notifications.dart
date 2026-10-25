import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// What tapping the reminder asks the app to do.
const String reminderPayload = 'quick_entry';

/// Phone notifications for the daily reminder, scheduled on the device (no
/// server). Only the Android app has them: a browser can't be relied on to
/// show a notification at a set time.
abstract class ReminderNotifications {
  /// Whether this platform can show the reminder at all.
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static ReminderNotifications instance =
      supported ? _AndroidReminders() : _NoReminders();

  /// Set when the user taps a reminder (also one that opened the app); the
  /// shell opens quick entry and clears it.
  static final ValueNotifier<bool> tapped = ValueNotifier<bool>(false);

  /// Prepares the plugin and notes a tap that launched the app.
  Future<void> init();

  /// Asks for permission to notify (Android 13+); true when granted.
  Future<bool> requestPermission();

  /// Whether notifications are allowed for the app right now.
  Future<bool> allowed();

  /// Opens the phone's notification settings for the app.
  Future<void> openSystemSettings();

  /// Replaces every scheduled reminder with one at each of [times].
  Future<void> schedule(List<DateTime> times,
      {required String title, required String body, required String channel});

  /// Removes every scheduled reminder.
  Future<void> cancel();
}

class _NoReminders extends ReminderNotifications {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> allowed() async => false;
  @override
  Future<void> openSystemSettings() async {}
  @override
  Future<void> schedule(List<DateTime> times,
      {required String title,
      required String body,
      required String channel}) async {}
  @override
  Future<void> cancel() async {}
}

class _AndroidReminders extends ReminderNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  /// The reminders use ids 1 to 14; nothing else in the app posts any.
  static const int _firstId = 1;
  static const int _maxIds = 14;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() => _ready ??= _init();

  Future<void> _init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_reminder'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        if (r.payload == reminderPayload) {
          ReminderNotifications.tapped.value = true;
        }
      },
    );
    final NotificationAppLaunchDetails? launch =
        await _plugin.getNotificationAppLaunchDetails();
    if ((launch?.didNotificationLaunchApp ?? false) &&
        launch?.notificationResponse?.payload == reminderPayload) {
      ReminderNotifications.tapped.value = true;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> allowed() async {
    await init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> openSystemSettings() async {
    await init();
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> schedule(List<DateTime> times,
      {required String title,
      required String body,
      required String channel}) async {
    await init();
    await cancel();
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        channel,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
    int id = _firstId;
    for (final DateTime at in times.take(_maxIds)) {
      // The exact instant, so a clock change (summer time) between now and
      // then can't move it.
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: details,
        // Within a few minutes is fine for a reminder, and needs no
        // exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: reminderPayload,
      );
    }
  }

  @override
  Future<void> cancel() async {
    await init();
    for (int id = _firstId; id < _firstId + _maxIds; id++) {
      await _plugin.cancel(id: id);
    }
  }
}
