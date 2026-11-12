import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/trial_reminder.dart';

/// The trial reminder due now (null: none). Follows the account's entitlement,
/// so it is worked out again whenever the server's answer comes in (the app
/// asks again each time it comes back into view).
final trialReminderProvider = Provider<TrialReminder?>((ref) {
  if (!ref.watch(authControllerProvider).isAuthenticated) return null;
  final Entitlement e = ref.watch(remoteEntitlementProvider).valueOrNull ??
      ref.watch(entitlementProvider);
  return trialReminderAt(e, AppClock.now());
});

/// Which reminders the user closed: «account|trial end|kind», so each
/// reminder of each trial is shown once and a closed one stays closed.
final trialReminderDismissedProvider =
    NotifierProvider<TrialReminderDismissed, Set<String>>(
        TrialReminderDismissed.new);

class TrialReminderDismissed extends Notifier<Set<String>> {
  static const String _key = 'sb_trial_reminders_closed';

  @override
  Set<String> build() {
    _load();
    return const <String>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String>? saved = p.getStringList(_key);
      if (saved != null) state = <String>{...state, ...saved};
    } catch (_) {
      // Shown again at worst.
    }
  }

  Future<void> dismiss(String id) async {
    state = <String>{...state, id};
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList(_key, state.toList());
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The id a closed reminder is remembered by, or null when there is none to
/// show.
final trialReminderIdProvider = Provider<String?>((ref) {
  final TrialReminder? r = ref.watch(trialReminderProvider);
  final String? account = ref.watch(currentAccountIdProvider);
  if (r == null || account == null) return null;
  final Entitlement e = ref.watch(remoteEntitlementProvider).valueOrNull ??
      ref.watch(entitlementProvider);
  final String ends = e.trialExpiresAt?.toUtc().toIso8601String() ?? '';
  return '$account|$ends|${r.kind.name}';
});
