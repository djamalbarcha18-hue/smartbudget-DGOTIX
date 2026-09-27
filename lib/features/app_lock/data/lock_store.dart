import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/app_lock/domain/lock_config.dart';

/// Persists the lock settings on this device (shared by every account on it).
abstract final class LockStore {
  static const String key = 'sb_app_lock';

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
    }
  }

  /// "Forgot PIN": wipes everything this app stored on the device.
  static Future<void> eraseDevice() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
