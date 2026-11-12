/// When to remind the user that the free PRO trial is about to end.
///
/// Two reminders near the end: the third day before (a few days to decide) and
/// the last day. Nothing is said before that or after the trial: a trial that
/// was bought into, or that already ended, gets none. The reminder only says
/// what happens (the data stays); it names no price and links nowhere, so it
/// is as fit for the store app as for the website.
library;

import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

enum TrialReminderKind { endingSoon, endsToday }

class TrialReminder {
  const TrialReminder(this.kind, this.daysLeft);

  final TrialReminderKind kind;

  /// Whole days left, rounded up (2 or 3 for [TrialReminderKind.endingSoon],
  /// 1 for [TrialReminderKind.endsToday]).
  final int daysLeft;
}

/// How many days before the end the first reminder shows.
const int kTrialReminderDays = 3;

/// The reminder to show at [now], or null when there is none.
TrialReminder? trialReminderAt(Entitlement e, DateTime now) {
  final DateTime? ends = e.trialExpiresAt;
  // Only a running trial of an account that doesn't pay.
  if (e.plan != Plan.free || ends == null || !e.trialActiveAt(now)) return null;
  final Duration left = ends.difference(now);
  if (left <= Duration.zero) return null;
  final int days =
      (left.inMinutes + Duration.minutesPerDay - 1) ~/ Duration.minutesPerDay;
  if (days <= 1) return const TrialReminder(TrialReminderKind.endsToday, 1);
  if (days <= kTrialReminderDays) {
    return TrialReminder(TrialReminderKind.endingSoon, days);
  }
  return null;
}
