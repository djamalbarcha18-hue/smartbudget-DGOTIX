import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';

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

final subscriptionActionsProvider =
    Provider<SubscriptionActions>(SubscriptionActions.new);

class SubscriptionActions {
  SubscriptionActions(this._ref);
  final Ref _ref;

  LocalListStore<Subscription> get _store =>
      _ref.read(subscriptionStoreProvider);

  /// A new id; its rule uses the same one ([Subscription.idPrefix]).
  static String newId() =>
      '${Subscription.idPrefix}${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> save(Subscription s) => _store.upsert(s);

  Future<void> delete(String id) => _store.delete(id);
}
