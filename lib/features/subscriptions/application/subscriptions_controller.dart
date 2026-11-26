import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';

/// The user's subscriptions, on the device (synced and backed up with the
/// rest). Their amounts and schedules are recurring rules.
final subscriptionStoreProvider =
    Provider<LocalListStore<Subscription>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<Subscription> store = LocalListStore<Subscription>(
    key: 'sb_subscriptions_$userId',
    fromJson: Subscription.fromJson,
    toJson: (Subscription s) => s.toJson(),
    idOf: (Subscription s) => s.id,
    compare: (Subscription a, Subscription b) =>
        a.provider.toLowerCase().compareTo(b.provider.toLowerCase()),
  );
  ref.onDispose(store.dispose);
  return store;
});

final subscriptionsProvider = StreamProvider<List<Subscription>>(
    (ref) => ref.watch(subscriptionStoreProvider).watchAll());

/// A subscription with its rule (null while the rule hasn't loaded or was
/// removed on another device).
typedef SubscriptionItem = ({Subscription sub, RecurringRule? rule});

/// Every subscription with its rule, by next charge (those without a rule
/// last).
final subscriptionItemsProvider = Provider<List<SubscriptionItem>>((ref) {
  final List<Subscription> subs =
      ref.watch(subscriptionsProvider).valueOrNull ?? const <Subscription>[];
  final Map<String, RecurringRule> rules = <String, RecurringRule>{
    for (final RecurringRule r
        in ref.watch(recurringRulesProvider).valueOrNull ??
            const <RecurringRule>[])
      r.id: r,
  };
  final DateTime now = AppClock.now();
  final List<SubscriptionItem> out = <SubscriptionItem>[
    for (final Subscription s in subs) (sub: s, rule: rules[s.ruleId]),
  ];
  DateTime? next(SubscriptionItem i) =>
      i.rule == null ? null : SubscriptionSchedule.nextCharge(i.rule!, now);
  out.sort((SubscriptionItem a, SubscriptionItem b) {
    final DateTime? x = next(a), y = next(b);
    if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
    return x.compareTo(y);
  });
  return out;
});

final subscriptionActionsProvider =
    Provider<SubscriptionActions>(SubscriptionActions.new);

class SubscriptionActions {
  SubscriptionActions(this._ref);
  final Ref _ref;

  LocalListStore<Subscription> get _store =>
      _ref.read(subscriptionStoreProvider);
  RecurringRepository get _rules => _ref.read(recurringRepositoryProvider);

  /// A new id; its rule uses the same one ([Subscription.idPrefix]).
  static String newId() =>
      '${Subscription.idPrefix}${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Saves [s] (new or edited) with its rule: [amount] every [frequency],
  /// next charged on [nextCharge]. The rule is written first, so a
  /// subscription never exists without its schedule.
  Future<void> save(
    Subscription s, {
    required Money amount,
    required RecurrenceFrequency frequency,
    required DateTime nextCharge,
  }) async {
    // The loaded list (the repository's own may not be loaded yet, and adding
    // to it then would duplicate the rule).
    final List<RecurringRule> all =
        await _ref.read(recurringRulesProvider.future);
    final RecurringRule? old =
        all.where((RecurringRule r) => r.id == s.ruleId).firstOrNull;
    final RecurringRule rule = SubscriptionSchedule.ruleFor(
      id: s.ruleId,
      provider: s.provider,
      amount: amount,
      frequency: frequency,
      nextCharge: nextCharge,
      createdAt: old?.createdAt ?? AppClock.now(),
      walletId: old?.walletId,
      notes: old?.notes,
    );
    if (old == null) {
      await _rules.add(rule);
    } else {
      // Only future dates move: what was recorded before keeps its date.
      await _rules.update(rule.lastPosted.isBefore(old.lastPosted)
          ? rule.copyWith(lastPosted: old.lastPosted)
          : rule);
    }
    await _store.upsert(s.copyWith(updatedAt: AppClock.now()));
  }

  /// Removes [s] and its rule. Expenses already recorded stay.
  Future<void> delete(Subscription s) async {
    await _store.delete(s.id);
    await _rules.delete(s.ruleId);
  }
}
