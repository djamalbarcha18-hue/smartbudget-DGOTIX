import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';

/// What a reminder is about.
enum SubscriptionAlertKind {
  /// It renews and charges on its own: keep or cancel before.
  renewal,

  /// The free trial ends and the first paid charge comes.
  trialEnd,

  /// A plan renewed by hand (a prepaid phone plan) runs out.
  planEnds,
}

/// One phone reminder, ready to schedule (the text is written by the app in
/// the user's language).
class SubscriptionAlert {
  const SubscriptionAlert({
    required this.subscriptionId,
    required this.provider,
    required this.amount,
    required this.charge,
    required this.daysBefore,
    required this.at,
    required this.kind,
  });

  final String subscriptionId;
  final String provider;
  final Money amount;

  /// The charge (or end) it warns about.
  final DateTime charge;
  final int daysBefore;

  /// When it shows, in local time.
  final DateTime at;
  final SubscriptionAlertKind kind;

  /// Whole days from the day it shows to the charge, for its text ("in 3
  /// days", "tomorrow"): a reminder moved out of quiet hours to the evening
  /// before says so truthfully.
  int get daysLeft => DateTime.utc(charge.year, charge.month, charge.day)
      .difference(DateTime.utc(at.year, at.month, at.day))
      .inDays;
}

/// Which reminders to put on the phone (pure: no Flutter, no IO).
///
/// Reminders are scheduled ahead on the device, so they come with the app
/// closed. Only a window ahead is scheduled (Android caps the alarms an app
/// may hold); it is planned again whenever the app opens, a subscription
/// changes or a sync lands.
abstract final class SubscriptionAlerts {
  /// Default time of day: 10:00.
  static const int defaultMinutes = 10 * 60;

  /// Quiet hours: 22:00 to 08:00. A reminder there moves EARLIER (21:00, the
  /// evening before for an early-morning time), never later, so it can't
  /// come after the last moment to cancel.
  static const int quietFrom = 22 * 60;
  static const int quietUntil = 8 * 60;
  static const int quietFallback = 21 * 60;

  /// How far ahead reminders are scheduled, and at most how many.
  static const int horizonDays = 60;
  static const int maxAlerts = 60;

  /// The moment a reminder on [day] shows at [minutes] after midnight.
  static DateTime momentOn(DateTime day, int minutes) {
    final int m = minutes.clamp(0, 24 * 60 - 1);
    if (m >= quietFrom) {
      return DateTime(day.year, day.month, day.day, quietFallback ~/ 60,
          quietFallback % 60);
    }
    if (m < quietUntil) {
      return DateTime(day.year, day.month, day.day - 1, quietFallback ~/ 60,
          quietFallback % 60);
    }
    return DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
  }

  /// The reminders still ahead of [now] for [items] (a subscription with its
  /// rule), soonest first, at most [maxAlerts].
  static List<SubscriptionAlert> plan(
    Iterable<({Subscription sub, RecurringRule? rule})> items,
    DateTime now, {
    int minutes = defaultMinutes,
  }) {
    final DateTime today = RecurrenceEngine.dateOnly(now);
    final DateTime horizon =
        DateTime(today.year, today.month, today.day + horizonDays);
    final List<SubscriptionAlert> out = <SubscriptionAlert>[];
    for (final ({Subscription sub, RecurringRule? rule}) i in items) {
      final Subscription s = i.sub;
      final RecurringRule? r = i.rule;
      if (r == null || !s.remindersOn || s.isOver) continue;
      DateTime charge = SubscriptionSchedule.nextCharge(r, now);
      while (!charge.isAfter(horizon)) {
        // Cancelled, usable until the end of the paid period: nothing after.
        final DateTime? paid = s.paidUntil;
        if (s.status == SubscriptionStatus.activeUntilEnd &&
            paid != null &&
            charge.isAfter(paid)) {
          break;
        }
        // "Keep it" silences this cycle only.
        final DateTime? kept = s.keptUntil;
        final bool silenced = kept != null && !charge.isAfter(kept);
        if (!silenced) {
          final bool trial = s.trialEndsOn(charge);
          final List<int> days = trial
              ? SubscriptionReminders.trialDays
              : SubscriptionReminders.daysFor(s, r.frequency);
          final SubscriptionAlertKind kind = trial
              ? SubscriptionAlertKind.trialEnd
              : (s.autoRenew
                  ? SubscriptionAlertKind.renewal
                  : SubscriptionAlertKind.planEnds);
          for (final int d in days) {
            final DateTime day =
                DateTime(charge.year, charge.month, charge.day - d);
            final DateTime at = momentOn(day, s.reminderMinutes ?? minutes);
            if (!at.isAfter(now)) continue;
            out.add(SubscriptionAlert(
              subscriptionId: s.id,
              provider: s.provider,
              amount: r.amount,
              charge: charge,
              daysBefore: d,
              at: at,
              kind: kind,
            ));
          }
        }
        charge = RecurrenceEngine.nextAfter(r, charge);
      }
    }
    out.sort((SubscriptionAlert a, SubscriptionAlert b) => a.at.compareTo(b.at));
    return out.length > maxAlerts ? out.sublist(0, maxAlerts) : out;
  }
}
