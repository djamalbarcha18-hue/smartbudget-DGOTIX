import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';

final seasonStoreProvider = Provider<LocalListStore<SeasonPlan>>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final LocalListStore<SeasonPlan> store = LocalListStore<SeasonPlan>(
    key: 'sb_seasons_$userId',
    fromJson: SeasonPlan.fromJson,
    toJson: (SeasonPlan p) => p.toJson(),
    idOf: (SeasonPlan p) => p.id,
    compare: (SeasonPlan a, SeasonPlan b) => a.start.compareTo(b.start),
  );
  ref.onDispose(store.dispose);
  return store;
});

final seasonPlansProvider = StreamProvider<List<SeasonPlan>>(
    (ref) => ref.watch(seasonStoreProvider).watchAll());

final seasonActionsProvider = Provider<SeasonActions>(SeasonActions.new);

class SeasonActions {
  SeasonActions(this._ref);
  final Ref _ref;

  LocalListStore<SeasonPlan> get _store => _ref.read(seasonStoreProvider);

  static String newId() =>
      'season-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> save(SeasonPlan p) => _store.upsert(p);

  Future<void> delete(String id) => _store.delete(id);

  Future<void> contribute(SeasonPlan p, Money amount) =>
      _store.upsert(p.copyWith(saved: p.saved + amount));
}
