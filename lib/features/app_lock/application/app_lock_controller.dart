import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/app_lock/data/device_auth.dart';
import 'package:smartbudget/features/app_lock/data/lock_store.dart';
import 'package:smartbudget/features/app_lock/domain/lock_config.dart';

/// The settings read at startup (overridden in main) so a locked app never
/// flashes its content before the lock screen.
final initialLockConfigProvider =
    Provider<LockConfig>((ref) => const LockConfig());

final deviceAuthAvailableProvider =
    FutureProvider<bool>((ref) => deviceAuthAvailable());

class AppLockState {
  const AppLockState({
    required this.config,
    required this.locked,
    this.failures = 0,
    this.retryAt,
  });

  final LockConfig config;
  final bool locked;
  final int failures;
  final DateTime? retryAt;

  AppLockState copyWith({
    LockConfig? config,
    bool? locked,
    int? failures,
    DateTime? retryAt,
    bool clearRetry = false,
  }) =>
      AppLockState(
        config: config ?? this.config,
        locked: locked ?? this.locked,
        failures: failures ?? this.failures,
        retryAt: clearRetry ? null : retryAt ?? this.retryAt,
      );
}

enum PinResult { ok, wrong, waiting }

final appLockProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);

class AppLockController extends Notifier<AppLockState> {
  DateTime? _hiddenAt;

  @override
  AppLockState build() {
    final LockConfig c = ref.watch(initialLockConfigProvider);
    return AppLockState(config: c, locked: c.enabled);
  }

  Duration get waitRemaining {
    final DateTime? at = state.retryAt;
    if (at == null) return Duration.zero;
    final Duration d = at.difference(AppClock.now());
    return d.isNegative ? Duration.zero : d;
  }

  PinResult unlockWithPin(String pin) {
    if (waitRemaining > Duration.zero) return PinResult.waiting;
    if (state.config.matches(pin)) {
      state = state.copyWith(locked: false, failures: 0, clearRetry: true);
      return PinResult.ok;
    }
    _fail();
    return PinResult.wrong;
  }

  /// "Forgot PIN": checks the recovery code without unlocking yet (a new PIN
  /// comes first). Wrong codes count toward the same lock-out as PINs.
  PinResult checkRecovery(String code) {
    if (waitRemaining > Duration.zero) return PinResult.waiting;
    if (state.config.matchesRecovery(code)) {
      state = state.copyWith(failures: 0, clearRetry: true);
      return PinResult.ok;
    }
    _fail();
    return PinResult.wrong;
  }

  /// Sets [newPin] after a valid recovery [code] and returns the NEW recovery
  /// code (the used one is retired). The app stays locked until
  /// [finishRecovery], so the new code can be shown first.
  Future<String?> resetWithRecovery(String code, String newPin) async {
    if (!state.config.matchesRecovery(code)) return null;
    final String fresh = RecoveryCode.generate();
    await _save(state.config.withPin(newPin).withRecovery(fresh),
        locked: true);
    return fresh;
  }

  void finishRecovery() => state = state.copyWith(locked: false);

  void _fail() {
    final int f = state.failures + 1;
    final Duration wait = lockoutAfter(f);
    state = state.copyWith(
      failures: f,
      retryAt: wait == Duration.zero ? null : AppClock.now().add(wait),
      clearRetry: wait == Duration.zero,
    );
  }

  Future<bool> unlockWithDevice() async {
    final String? id = state.config.credentialId;
    if (id == null) return false;
    final bool ok = await verifyDeviceAuth(id);
    if (ok) {
      state = state.copyWith(locked: false, failures: 0, clearRetry: true);
    }
    return ok;
  }

  void lock() {
    if (state.config.enabled) state = state.copyWith(locked: true);
  }

  void onHidden() => _hiddenAt = AppClock.now();

  void onShown() {
    final DateTime? at = _hiddenAt;
    _hiddenAt = null;
    if (at == null || !state.config.enabled || state.locked) return;
    final Duration away = AppClock.now().difference(at);
    if (away >= Duration(minutes: state.config.autoLockMinutes)) lock();
  }

  bool checkPin(String pin) => state.config.matches(pin);

  /// Changes the PIN (the recovery code stays valid).
  Future<void> setPin(String pin) => _save(state.config.withPin(pin));

  /// Turns the lock on with [pin] and returns its recovery code, which is
  /// shown once and never stored in clear.
  Future<String> enable(String pin) async {
    final String code = RecoveryCode.generate();
    await _save(state.config.withPin(pin).withRecovery(code));
    return code;
  }

  /// Replaces the recovery code (the old one stops working).
  Future<String> newRecoveryCode() async {
    final String code = RecoveryCode.generate();
    await _save(state.config.withRecovery(code));
    return code;
  }

  Future<void> disable() => _save(const LockConfig());

  Future<void> setAutoLock(int minutes) =>
      _save(state.config.copyWith(autoLockMinutes: minutes));

  Future<bool> enableDeviceUnlock(String userName) async {
    final String? id = await registerDeviceAuth(userName: userName);
    if (id == null) return false;
    await _save(state.config.copyWith(credentialId: id));
    return true;
  }

  Future<void> disableDeviceUnlock() =>
      _save(state.config.copyWith(clearCredential: true));

  /// "Forgot PIN": erase this device's data and start over.
  Future<void> eraseAndRestart() async {
    await LockStore.eraseDevice();
    reloadApp();
  }

  Future<void> _save(LockConfig c, {bool locked = false}) async {
    await LockStore.save(c);
    state = state.copyWith(config: c, locked: locked);
  }
}
