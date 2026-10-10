import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/network/connectivity.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/application/backup_controller.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/challenges/application/challenges_controller.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/sync/data/sync_remote.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';

enum SyncPhase { off, idle, syncing, offline, error }

class SyncStatus {
  const SyncStatus(this.phase, {this.lastSyncedAt});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;

  SyncStatus copyWith({SyncPhase? phase, DateTime? lastSyncedAt}) =>
      SyncStatus(phase ?? this.phase,
          lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt);
}

/// Whether there is a cloud to sync with (a real Supabase project).
final syncAvailableProvider = Provider<bool>((_) => AppEnv.hasSupabase);

/// The account's "sync across devices" setting (on by default).
final syncEnabledProvider =
    NotifierProvider<SyncEnabledController, bool>(SyncEnabledController.new);

class SyncEnabledController extends Notifier<bool> {
  static const String _base = 'sb_sync_enabled';

  @override
  bool build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _load(account);
    return true;
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final bool? v = p.getBool(AccountKeys.of(_base, account));
      if (v != null && ref.read(currentAccountIdProvider) == account) state = v;
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> set(bool on) async {
    state = on;
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setBool(
        AccountKeys.of(_base, ref.read(currentAccountIdProvider)), on);
  }
}

/// Keeps this device and the account's cloud copy in step, automatically:
/// shortly after any change, on start, when the connection comes back, when
/// the app returns to the screen and every few minutes. Changes are noticed
/// (and timed) even offline, so the newest change still wins once online.
/// See [SyncMerge].
final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatus>(SyncController.new);

class SyncController extends Notifier<SyncStatus> {
  static const String _ledgerBase = 'sb_sync_ledger';
  static const String _lastBase = 'sb_sync_last';
  static const Duration afterChange = Duration(seconds: 4);
  static const Duration every = Duration(minutes: 10);

  String? _account;
  Timer? _timer;
  Timer? _periodic;
  AppLifecycleListener? _life;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  bool _running = false;
  bool _again = false;
  DateTime _quietUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  /// Signed in, sync on and a cloud to sync with (set before listening, as a
  /// listener may fire while build() runs).
  bool _active = false;

  @override
  SyncStatus build() {
    _disposed = false;
    _active = false;
    final String? account = ref.watch(currentAccountIdProvider);
    final bool enabled = ref.watch(syncEnabledProvider);
    ref.onDispose(_stop);
    // Automatic sync across devices is part of the paid plans.
    final bool included =
        ref.watch(featureGateProvider(Feature.cloudSyncFull)).allowed;
    if (!ref.watch(syncAvailableProvider) ||
        account == null ||
        !enabled ||
        !included) {
      return const SyncStatus(SyncPhase.off);
    }
    _account = account;
    _active = true;
    _start();
    _loadLast(account);
    return const SyncStatus(SyncPhase.idle);
  }

  void _start() {
    void changed() {
      if (AppClock.now().isBefore(_quietUntil)) return; // our own apply
      schedule(afterChange);
    }

    ref.listen(onlineProvider, (AsyncValue<bool>? prev, AsyncValue<bool> next) {
      if (next.valueOrNull == true && prev?.valueOrNull != true) {
        schedule(Duration.zero);
      }
    });
    ref.listen(transactionsProvider, (_, __) => changed());
    ref.listen(budgetsProvider, (_, __) => changed());
    ref.listen(goalsProvider, (_, __) => changed());
    ref.listen(debtsProvider, (_, __) => changed());
    ref.listen(projectsProvider, (_, __) => changed());
    ref.listen(recurringRulesProvider, (_, __) => changed());
    ref.listen(customCategoriesProvider, (_, __) => changed());
    ref.listen(baseCurrencyProvider, (_, __) => changed());
    for (final Stream<Object?> s in <Stream<Object?>>[
      ref.read(seasonStoreProvider).watchAll(),
      ref.read(daretStoreProvider).watchAll(),
      ref.read(challengeStoreProvider).watchAll(),
      ref.read(walletStoreProvider).watchAll(),
      ref.read(walletMoveStoreProvider).watchAll(),
    ]) {
      _subs.add(s.listen((_) => changed()));
    }
    _periodic = Timer.periodic(every, (_) => schedule(Duration.zero));
    _life = AppLifecycleListener(
      onResume: () => schedule(Duration.zero),
      onShow: () => schedule(Duration.zero),
    );
    schedule(const Duration(seconds: 2));
  }

  void _stop() {
    _disposed = true;
    _active = false;
    // May run twice (a rebuild, then the container going away).
    _timer?.cancel();
    _timer = null;
    _periodic?.cancel();
    _periodic = null;
    _life?.dispose();
    _life = null;
    for (final StreamSubscription<Object?> s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  Future<void> _loadLast(String account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final int? ms = p.getInt(AccountKeys.of(_lastBase, account));
      if (ms != null && !_disposed && _account == account) {
        state = state.copyWith(
            lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(ms));
      }
    } catch (_) {}
  }

  /// Syncs after [delay] (a newer call replaces a pending one).
  void schedule(Duration delay) {
    if (_disposed || !_active) return;
    _timer?.cancel();
    _timer = Timer(delay, syncNow);
  }

  /// One sync round now (or right after the one running).
  Future<void> syncNow() async {
    if (_disposed || !_active) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      await _round();
    } catch (_) {
      if (!_disposed) state = state.copyWith(phase: SyncPhase.error);
    } finally {
      _running = false;
      if (_again && !_disposed) {
        _again = false;
        schedule(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _round() async {
    final String account = _account!;
    final BackupService backup = ref.read(backupServiceProvider);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String ledgerKey = AccountKeys.of(_ledgerBase, account);
    final int now = AppClock.now().millisecondsSinceEpoch;

    // 1. Notice this device's changes (works offline).
    Records records = await _records(backup);
    Entries local =
        SyncMerge.detect(_ledger(prefs.getString(ledgerKey)), records, now);
    await prefs.setString(ledgerKey, jsonEncode(SyncMerge.ledgerToJson(local)));

    if (ref.read(isOfflineProvider)) {
      state = state.copyWith(phase: SyncPhase.offline);
      return;
    }
    state = state.copyWith(phase: SyncPhase.syncing);

    // 2. Merge with the cloud copy, apply, upload; again if another device
    //    uploaded in between.
    final SyncRemote remote = ref.read(syncRemoteProvider);
    for (int attempt = 0; attempt < 3; attempt++) {
      final RemoteCopy copy = await remote.pull();
      if (_disposed || _account != account) return;
      final Entries cloud = SyncMerge.fromCloud(copy.doc);
      Entries merged = SyncMerge.merge(local, cloud, now: now);
      final Records target = SyncMerge.recordsOf(merged);
      if (!SyncMerge.sameRecords(records, target)) {
        _quietUntil = AppClock.now().add(const Duration(seconds: 3));
        await backup.replaceAll(
          BackupData.fromJson(SyncMerge.backupFromRecords(target)),
          setBaseCurrency: target['settings']?['baseCurrency'] != null,
        );
        records = await _records(backup);
        _quietUntil = AppClock.now().add(const Duration(seconds: 2));
      }
      merged = SyncMerge.rebase(merged, records);
      await prefs.setString(
          ledgerKey, jsonEncode(SyncMerge.ledgerToJson(merged)));
      local = merged;
      if (SyncMerge.same(merged, cloud) ||
          await remote.push(SyncMerge.toCloud(merged), copy)) {
        final DateTime at = AppClock.now();
        await prefs.setInt(
            AccountKeys.of(_lastBase, account), at.millisecondsSinceEpoch);
        ref.read(backupStatusProvider.notifier).markBackedUp().ignore();
        state = SyncStatus(SyncPhase.idle, lastSyncedAt: at);
        return;
      }
    }
    state = state.copyWith(phase: SyncPhase.error);
  }

  static Future<Records> _records(BackupService backup) async =>
      SyncMerge.recordsFromBackup((await backup.snapshot()).toJson());

  static Entries _ledger(String? raw) {
    if (raw == null || raw.isEmpty) return <String, Map<String, SyncEntry>>{};
    try {
      return SyncMerge.ledgerFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return <String, Map<String, SyncEntry>>{};
    }
  }
}
