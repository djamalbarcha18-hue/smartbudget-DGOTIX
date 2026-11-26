import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/data/subscription_notifications.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_alerts.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Keeps the phone's subscription reminders in step with the subscriptions:
/// planned again when they change (an edit here, a sync from another
/// device), when the app comes back to the front, and once on start. Opens
/// the subscription whose reminder was tapped. Invisible; wraps the routed
/// page.
///
/// A failure here is swallowed: reminders must never get in the way of the
/// rest of the app; the next trigger retries.
class SubscriptionReminderScheduler extends ConsumerStatefulWidget {
  const SubscriptionReminderScheduler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SubscriptionReminderScheduler> createState() =>
      _SubscriptionReminderSchedulerState();
}

class _SubscriptionReminderSchedulerState
    extends ConsumerState<SubscriptionReminderScheduler> {
  Timer? _debounce;
  AppLifecycleListener? _life;

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<SubscriptionItem>>(
      subscriptionItemsProvider,
      (_, __) => _later(),
      fireImmediately: true,
    );
    _life = AppLifecycleListener(onResume: _later);
    ReminderNotifications.subscriptionTapped.addListener(_onTap);
    // A tap that launched the app came before this was built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _life?.dispose();
    ReminderNotifications.subscriptionTapped.removeListener(_onTap);
    super.dispose();
  }

  /// Several changes in a row (a sync writes many) are planned once.
  void _later() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _schedule);
  }

  Future<void> _schedule() async {
    if (!mounted || !SubscriptionNotifications.supported) return;
    // Until both lists are read, an empty one would cancel every reminder.
    if (!ref.read(subscriptionsProvider).hasValue ||
        !ref.read(recurringRulesProvider).hasValue) {
      return;
    }
    try {
      final AppLocalizations l = AppLocalizations.of(context);
      final List<SubscriptionAlert> alerts = SubscriptionAlerts.plan(
          ref.read(subscriptionItemsProvider), AppClock.now());
      await SubscriptionNotifications.instance.schedule(
        <SubscriptionNotice>[
          for (final SubscriptionAlert a in alerts)
            SubscriptionNotice(alert: a, title: a.provider, body: bodyOf(l, a)),
        ],
        renewalChannel: l.subNotifChannelRenew,
        trialChannel: l.subNotifChannelTrial,
      );
    } catch (_) {
      // The next change or return to the app tries again.
    }
  }

  void _onTap() {
    final String? id = ReminderNotifications.subscriptionTapped.value;
    if (!mounted || id == null) return;
    ReminderNotifications.subscriptionTapped.value = null;
    context.go('/recurring');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final SubscriptionItem i in ref.read(subscriptionItemsProvider)) {
        if (i.sub.id == id) {
          SubscriptionEditorSheet.show(context, existing: i);
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The reminder's text: what is charged and when, asking for a decision.
String bodyOf(AppLocalizations l, SubscriptionAlert a) {
  final String amount = MoneyFormatter.format(a.amount);
  return switch (a.kind) {
    SubscriptionAlertKind.renewal => l.subNotifRenew(a.daysLeft, amount),
    SubscriptionAlertKind.trialEnd => l.subNotifTrial(a.daysLeft, amount),
    SubscriptionAlertKind.planEnds => l.subNotifPlanEnds(a.daysLeft),
  };
}
