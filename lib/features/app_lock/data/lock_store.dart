import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/app_lock/domain/lock_config.dart';

/// Wrong PIN / recovery attempts and the wait they impose, kept on the device
/// so closing and reopening the app doesn't reset the lock-out.
class LockAttempts {
  const LockAttempts({this.failures = 0, this.retryAt});

  final int failures;
  final DateTime? retryAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'f': failures,
        if (retryAt != null) 'at': retryAt!.toIso8601String(),
      };

  factory LockAttempts.fromJson(Map<String, dynamic> j) => LockAttempts(
        failures: (j['f'] as num?)?.toInt() ?? 0,
        retryAt: DateTime.tryParse('${j['at'] ?? ''}'),
      );
}

/// Persists the lock settings on this device (shared by every account on it).
abstract final class LockStore {
  static const String key = 'sb_app_lock';
  static const String attemptsKey = 'sb_app_lock_attempts';

  static Future<LockAttempts> loadAttempts() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(attemptsKey);
      if (raw == null || raw.isEmpty) return const LockAttempts();
      return LockAttempts.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LockAttempts();
    }
  }

  static Future<void> saveAttempts(LockAttempts a) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (a.failures == 0 && a.retryAt == null) {
        await p.remove(attemptsKey);
      } else {
        await p.setString(attemptsKey, jsonEncode(a.toJson()));
      }
    } catch (_) {
      // The in-memory count still applies for this session.
    }
  }

  static Future<LockConfig> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(key);
      if (raw == null || raw.isEmpty) return const LockConfig();
      return LockConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LockConfig();
    }
  }

  static Future<void> save(LockConfig c) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (c.enabled) {
      await p.setString(key, jsonEncode(c.toJson()));
    } else {
      await p.remove(key);
      await p.remove(attemptsKey);
    }
  }

  /// "Forgot PIN": wipes everything this app stored on the device.
  static Future<void> eraseDevice() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
