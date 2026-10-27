import 'package:flutter/foundation.dart';

/// Whether the device is keeping what the user saves.
///
/// Every store reports here: a write that failed (the browser's storage is
/// full, the disk is full...) and the next one that worked. While any store
/// has unsaved changes the app says so and offers to try again and to
/// download a backup, which still holds them (they are kept in memory).
abstract final class SaveHealth {
  static final Map<String, Future<void> Function()> _retries =
      <String, Future<void> Function()>{};
  static final ValueNotifier<bool> _failing = ValueNotifier<bool>(false);

  /// True while some changes are not stored on the device.
  static ValueListenable<bool> get failing => _failing;

  /// The write of [key] failed; [retry] writes it again.
  static void failed(String key, Future<void> Function() retry) {
    _retries[key] = retry;
    _failing.value = true;
  }

  /// The write of [key] worked.
  static void saved(String key) {
    if (_retries.remove(key) != null) _failing.value = _retries.isNotEmpty;
  }

  /// Writes every failed store again. True when all of them are stored now.
  static Future<bool> retryAll() async {
    for (final Future<void> Function() retry
        in List<Future<void> Function()>.of(_retries.values)) {
      try {
        await retry();
      } catch (_) {
        // Still failing; it stays listed.
      }
    }
    return _retries.isEmpty;
  }

  @visibleForTesting
  static void reset() {
    _retries.clear();
    _failing.value = false;
  }
}
