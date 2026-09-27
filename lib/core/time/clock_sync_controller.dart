import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/core/time/network_time.dart';

class ClockStatus {
  const ClockStatus({
    required this.synced,
    required this.offset,
    required this.syncedAt,
    this.syncing = false,
    this.failed = false,
  });

  factory ClockStatus.current({bool syncing = false, bool failed = false}) =>
      ClockStatus(
        synced: AppClock.isSynced,
        offset: AppClock.offset,
        syncedAt: AppClock.syncedAt,
        syncing: syncing,
        failed: failed,
      );

  final bool synced;
  final Duration offset;
  final DateTime? syncedAt;
  final bool syncing;
  final bool failed;
}

final networkTimeProvider = Provider<NetworkTime>((ref) => NetworkTime());

/// Keeps [AppClock] in sync (every 30 minutes while the app is open) and
/// exposes its status to the Settings screen.
final clockSyncProvider =
    NotifierProvider<ClockSyncController, ClockStatus>(ClockSyncController.new);

class ClockSyncController extends Notifier<ClockStatus> {
  static const Duration interval = Duration(minutes: 30);

  @override
  ClockStatus build() {
    final Timer timer = Timer.periodic(interval, (_) => syncNow());
    ref.onDispose(timer.cancel);
    // The startup sync may have been skipped (offline, slow network): retry.
    if (!AppClock.isSynced) Future<void>.microtask(syncNow);
    return ClockStatus.current();
  }

  Future<void> syncNow() async {
    if (state.syncing) return;
    state = ClockStatus.current(syncing: true);
    final bool ok = await ref.read(networkTimeProvider).sync();
    state = ClockStatus.current(failed: !ok);
  }
}
