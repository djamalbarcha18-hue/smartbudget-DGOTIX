import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';

final daretStoreProvider = Provider<LocalListStore<Daret>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<Daret> store = LocalListStore<Daret>(
    key: 'sb_darets_$userId',
    fromJson: Daret.fromJson,
    toJson: (Daret d) => d.toJson(),
    idOf: (Daret d) => d.id,
    compare: (Daret a, Daret b) => a.start.compareTo(b.start),
  );
  ref.onDispose(store.dispose);
  return store;
});

final daretsProvider =
    StreamProvider<List<Daret>>((ref) => ref.watch(daretStoreProvider).watchAll());

final daretActionsProvider = Provider<DaretActions>(DaretActions.new);

class DaretActions {
  DaretActions(this._ref);
  final Ref _ref;

  LocalListStore<Daret> get _store => _ref.read(daretStoreProvider);

  static String newId() =>
      'daret-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> save(Daret d) => _store.upsert(d);

  Future<void> delete(String id) => _store.delete(id);

  Future<void> togglePaid(Daret d, int round) {
    final Set<int> paid = <int>{...d.paidRounds};
    if (!paid.remove(round)) paid.add(round);
    return _store.upsert(d.copyWith(paidRounds: paid));
  }

  Future<void> setReceived(Daret d, bool received) =>
      _store.upsert(d.copyWith(payoutReceived: received));
}
