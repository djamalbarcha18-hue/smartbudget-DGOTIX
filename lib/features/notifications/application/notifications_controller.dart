import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/notifications/domain/notification_feed.dart';
import 'package:smartbudget/features/notifications/domain/smart_alerts.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Ticks every 15 minutes so time-based notifications (a new day, a new
/// month, an item coming due) refresh while the app stays open.
final notificationClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
      const Duration(minutes: 15), (_) => DateTime.now());
});

/// The bell's notifications, always about TODAY (current month and year),
/// whatever period the user is browsing.
final notificationsProvider = Provider<List<FeedItem>>((ref) {
  final DateTime now =
      ref.watch(notificationClockProvider).valueOrNull ?? DateTime.now();
  final String currency = ref.watch(baseCurrencyProvider);
  final List<Transaction> txns =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final List<BudgetTarget> budgets =
      ref.watch(budgetsProvider).valueOrNull ?? const <BudgetTarget>[];
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  final List<RecurringRule> rules =
      ref.watch(recurringRulesProvider).valueOrNull ?? const <RecurringRule>[];
  final bool smartAllowed =
      ref.watch(featureGateProvider(Feature.smartAlerts)).allowed;

  final Map<String, int> planned = <String, int>{
    for (final BudgetTarget b in budgets)
      if (b.year == now.year && b.month == now.month)
        b.category: b.planned.minorUnits,
  };

  List<AppAlert> finance = const <AppAlert>[];
  List<AppAlert> smart = const <AppAlert>[];
  if (txns.isNotEmpty) {
    final List<Transaction> month =
        FinanceCalculator.forMonth(txns, now.year, now.month);
    finance = AlertEngine.build(
      plannedByCategory: planned,
      actualByCategory: <String, int>{
        for (final CategoryTotal t in FinanceCalculator.categoryTotals(
            month, TransactionType.expense, currency))
          t.category: t.amount.minorUnits,
      },
      goals: goals,
      yearSummary: FinanceCalculator.summarize(
          FinanceCalculator.forYear(txns, now.year), currency),
      currency: currency,
      now: now,
    );
    if (smartAllowed) {
      smart = SmartAlertEngine.build(
        transactions: txns,
        plannedThisMonth: planned,
        currency: currency,
        now: now,
      );
    }
  }

  return NotificationFeed.build(
    finance: finance,
    smart: smart,
    upcoming: NotificationFeed.upcomingRecurring(rules, now),
    backupDue: ref.watch(backupReminderDueProvider),
    currency: currency,
    now: now,
  );
});

/// Ids of notifications the user has already seen, per account. `null` until
/// loaded, so nothing is counted as new before we know.
final seenNotificationsProvider =
    NotifierProvider<SeenNotificationsController, Set<String>?>(
        SeenNotificationsController.new);

class SeenNotificationsController extends Notifier<Set<String>?> {
  late String _key;

  @override
  Set<String>? build() {
    final String userId =
        ref.watch(authControllerProvider).user?.id ?? 'guest';
    _key = 'sb_notif_seen_$userId';
    _load();
    return null;
  }

  Future<void> _load() async {
    Set<String> seen = <String>{};
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      seen = (p.getStringList(_key) ?? const <String>[]).toSet();
    } catch (_) {
      // Unavailable storage ⇒ everything counts as new.
    }
    state = seen;
  }

  /// Marks exactly [ids] (the notifications currently shown) as seen. Ids no
  /// longer active are dropped, so a problem that returns later is new again.
  Future<void> markSeen(Iterable<String> ids) async {
    final Set<String> next = ids.toSet();
    state = next;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList(_key, next.toList());
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// Ids of the current notifications the user hasn't seen yet.
final unreadNotificationsProvider = Provider<Set<String>>((ref) {
  final Set<String>? seen = ref.watch(seenNotificationsProvider);
  if (seen == null) return const <String>{};
  return NotificationFeed.unread(ref.watch(notificationsProvider), seen);
});
