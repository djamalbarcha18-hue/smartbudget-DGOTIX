import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/sync/application/sync_controller.dart';

/// True on a device that has never received the account's cloud copy while
/// sync is on its way (waiting for its first round, or in it). Offline, on a
/// sync error or with sync off it is false: there is nothing coming to wait
/// for. Read-only: it watches the sync status, it never starts a sync.
final firstCloudCopyPendingProvider = Provider<bool>((ref) {
  final SyncStatus s = ref.watch(syncControllerProvider);
  return s.lastSyncedAt == null &&
      (s.phase == SyncPhase.idle || s.phase == SyncPhase.syncing);
});

/// Whether a page has nothing to show yet but its data is on its way: the
/// device's own copy is still being read, or it is empty and the cloud copy
/// hasn't arrived on this device yet. Data already on the device is always
/// shown at once.
bool awaitingData<T>(AsyncValue<List<T>> local, {required bool cloudPending}) =>
    !local.hasValue || (local.requireValue.isEmpty && cloudPending);
