import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_alerts.dart';

/// One reminder with its text, ready for the phone.
class SubscriptionNotice {
  const SubscriptionNotice({
    required this.alert,
    required this.title,
    required this.body,
  });
  final SubscriptionAlert alert;
  final String title;
  final String body;
}

/// Subscription reminders scheduled on the phone (Android app only, like the
/// daily reminder: a browser can't be relied on to show one at a set time).
abstract class SubscriptionNotifications {
  static bool get supported => ReminderNotifications.supported;

  static SubscriptionNotifications instance =
      supported ? _AndroidSubscriptions() : _NoSubscriptions();

  /// Replaces every subscription reminder with [notices].
  /// Button ids in a reminder: [keepAction] silences this cycle,
  /// [cancelAction] opens the app on cancelling.
  static const String keepAction = 'keep';
  static const String cancelAction = 'cancel';

  /// The payload of a reminder for [alert]: the subscription and the charge
  /// it is about ("sub-x:20261215").
  static String payloadOf(SubscriptionAlert alert) {
    final DateTime d = alert.charge;
    final String ymd = '${d.year.toString().padLeft(4, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
    return '${alert.subscriptionId}:$ymd';
  }

  /// [payloadOf] read back, or null.
  static ({String id, DateTime charge})? parsePayload(String p) {
    final int at = p.lastIndexOf(':');
    if (at <= 0 || p.length - at - 1 != 8) return null;
    final String ymd = p.substring(at + 1);
    final int? y = int.tryParse(ymd.substring(0, 4)),
        m = int.tryParse(ymd.substring(4, 6)),
        d = int.tryParse(ymd.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return (id: p.substring(0, at), charge: DateTime(y, m, d));
  }

  Future<void> schedule(List<SubscriptionNotice> notices,
      {required String renewalChannel,
      required String trialChannel,
      required String keepLabel,
      required String cancelLabel});

  Future<void> cancel();
}

class _NoSubscriptions extends SubscriptionNotifications {
  @override
  Future<void> schedule(List<SubscriptionNotice> notices,
      {required String renewalChannel,
      required String trialChannel,
      required String keepLabel,
      required String cancelLabel}) async {}
  @override
  Future<void> cancel() async {}
}

class _AndroidSubscriptions extends SubscriptionNotifications {
  /// The same plugin as the daily reminder (it is set up there once).
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// The daily reminder uses 1 to 14, the Sadaqah planner 200 and up;
  /// subscriptions 1000 and up.
  static const int _firstId = 1000;

  @override
  Future<void> schedule(List<SubscriptionNotice> notices,
      {required String renewalChannel,
      required String trialChannel,
      required String keepLabel,
      required String cancelLabel}) async {
    await cancel();
    // Both buttons open the app, which then does the rest (no background
    // code to keep in step).
    final List<AndroidNotificationAction> actions = <AndroidNotificationAction>[
      AndroidNotificationAction(SubscriptionNotifications.keepAction, keepLabel,
          showsUserInterface: true),
      AndroidNotificationAction(
          SubscriptionNotifications.cancelAction, cancelLabel,
          showsUserInterface: true),
    ];
    NotificationDetails details(String id, String name, String body) =>
        NotificationDetails(
          android: AndroidNotificationDetails(
            id,
            name,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
            actions: actions,
          ),
        );
    int id = _firstId;
    for (final SubscriptionNotice n
        in notices.take(SubscriptionAlerts.maxAlerts)) {
      final bool trial = n.alert.kind == SubscriptionAlertKind.trialEnd;
      await _plugin.zonedSchedule(
        id: id++,
        // The exact instant, so a clock change can't move it.
        scheduledDate: tz.TZDateTime.from(n.alert.at.toUtc(), tz.UTC),
        notificationDetails: trial
            ? details('subscription_trials', trialChannel, n.body)
            : details('subscription_renewals', renewalChannel, n.body),
        // Within minutes is fine and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: '${ReminderNotifications.subscriptionPayloadPrefix}'
            '${SubscriptionNotifications.payloadOf(n.alert)}',
      );
    }
  }

  @override
  Future<void> cancel() async {
    await ReminderNotifications.instance.init();
    for (int id = _firstId; id < _firstId + SubscriptionAlerts.maxAlerts; id++) {
      await _plugin.cancel(id: id);
    }
  }
}
