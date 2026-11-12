import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/data/trial_service.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/domain/trial_reminder.dart';

/// The reminders near the end of the free PRO trial: a few days before, and
/// on the last day; none before, none after, none for someone who pays.
void main() {
  final DateTime now = DateTime.utc(2026, 11, 12, 10);
  Entitlement trial(Duration left, {Plan plan = Plan.free}) => Entitlement(
        plan: plan,
        trialPlan: Plan.pro,
        trialExpiresAt: now.add(left),
        trialUsed: true,
      );

  test('a trial in its first days has no reminder', () {
    expect(trialReminderAt(trial(const Duration(days: 13)), now), isNull);
    expect(trialReminderAt(trial(const Duration(days: 4)), now), isNull);
    expect(
        trialReminderAt(trial(const Duration(days: 3, minutes: 1)), now),
        isNull,
        reason: 'just over three days left is four days rounded up');
  });

  test('three days or less: «ends in N days»', () {
    TrialReminder? r = trialReminderAt(trial(const Duration(days: 3)), now);
    expect(r?.kind, TrialReminderKind.endingSoon);
    expect(r?.daysLeft, 3);
    r = trialReminderAt(trial(const Duration(days: 2, hours: 5)), now);
    expect(r?.kind, TrialReminderKind.endingSoon);
    expect(r?.daysLeft, 3);
    r = trialReminderAt(trial(const Duration(days: 2)), now);
    expect(r?.kind, TrialReminderKind.endingSoon);
    expect(r?.daysLeft, 2);
    r = trialReminderAt(trial(const Duration(days: 1, minutes: 1)), now);
    expect(r?.kind, TrialReminderKind.endingSoon);
    expect(r?.daysLeft, 2);
  });

  test('the last day: «ends today»', () {
    TrialReminder? r = trialReminderAt(trial(const Duration(days: 1)), now);
    expect(r?.kind, TrialReminderKind.endsToday);
    r = trialReminderAt(trial(const Duration(minutes: 5)), now);
    expect(r?.kind, TrialReminderKind.endsToday);
    expect(r?.daysLeft, 1);
  });

  test('an ended trial has no reminder', () {
    expect(trialReminderAt(trial(Duration.zero), now), isNull);
    expect(trialReminderAt(trial(const Duration(hours: -3)), now), isNull);
  });

  test('someone who pays, or never had a trial, has none', () {
    expect(
        trialReminderAt(trial(const Duration(days: 1), plan: Plan.pro), now),
        isNull);
    expect(trialReminderAt(Entitlement.free, now), isNull);
    expect(trialReminderAt(const Entitlement(plan: Plan.pro), now), isNull);
  });

  test('the server asking for a confirmed email is told apart', () {
    expect(TrialService.errorFrom('email_not_confirmed'),
        TrialError.emailNotConfirmed);
  });
}
