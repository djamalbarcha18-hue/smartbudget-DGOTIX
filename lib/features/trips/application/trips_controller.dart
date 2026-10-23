import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';

/// Trips, stored on the device like the other plans (and backed up and
/// synced with them).
final tripStoreProvider = Provider<LocalListStore<Trip>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<Trip> store = LocalListStore<Trip>(
    key: 'sb_trips_$userId',
    fromJson: Trip.fromJson,
    toJson: (Trip t) => t.toJson(),
    idOf: (Trip t) => t.id,
    compare: (Trip a, Trip b) => a.start.compareTo(b.start),
  );
  ref.onDispose(store.dispose);
  return store;
});

final tripsProvider = StreamProvider<List<Trip>>(
    (ref) => ref.watch(tripStoreProvider).watchAll());

/// The suggested places, read once from the app's own files (no network).
final destinationCatalogProvider =
    FutureProvider<DestinationCatalog>((ref) async {
  try {
    final String raw =
        await rootBundle.loadString('assets/data/destinations.json');
    Set<String>? bundled;
    try {
      bundled = (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
    } catch (_) {
      // Without the list every image is tried; a missing one shows the icon.
    }
    return DestinationCatalog.fromJson(raw, bundled: bundled);
  } catch (_) {
    return DestinationCatalog.empty;
  }
});

final tripActionsProvider = Provider<TripActions>(TripActions.new);

class TripActions {
  TripActions(this._ref);
  final Ref _ref;

  LocalListStore<Trip> get _store => _ref.read(tripStoreProvider);

  static String newId() =>
      'trip-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> save(Trip t) => _store.upsert(t);

  /// Deletes the trip; its expenses stay, no longer tagged with it.
  Future<void> delete(Trip t) async {
    final List<Transaction> txns =
        _ref.read(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final TransactionActions actions = _ref.read(transactionActionsProvider);
    for (final Transaction x in txns) {
      if (x.tripId == t.id) await actions.update(x.copyWith(clearTrip: true));
    }
    await _store.delete(t.id);
  }
}
