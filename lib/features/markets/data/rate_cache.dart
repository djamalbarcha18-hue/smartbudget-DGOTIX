import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A tiny TTL cache over shared_preferences for market responses.
///
/// Performance rule: the app never calls an API on every page open — a fresh
/// cached response (within [maxAge]) is reused, and a manual refresh clears the
/// cache to force a new fetch. Cached values are the raw decoded JSON.
class RateCache {
  const RateCache();

  static const String _prefix = 'sb_mkt_';
  static String _k(String key) => '$_prefix$key';

  /// Returns the cached value if present AND younger than [maxAge], else null.
  Future<dynamic> read(String key, {required Duration maxAge}) async {
    final _Entry? e = await _readEntry(key);
    if (e == null) return null;
    final int age = DateTime.now().millisecondsSinceEpoch - e.t;
    if (age > maxAge.inMilliseconds) return null;
    return e.v;
  }

  /// Returns the cached value regardless of age (used as a fallback when a live
  /// fetch fails), or null if nothing is cached.
  Future<dynamic> readStale(String key) async => (await _readEntry(key))?.v;

  Future<void> write(String key, dynamic value) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
        _k(key),
        jsonEncode(<String, dynamic>{
          't': DateTime.now().millisecondsSinceEpoch,
          'v': value,
        }),
      );
    } catch (_) {
      // Cache is best-effort.
    }
  }

  /// Clears every market cache entry (used by manual refresh to force a fetch).
  Future<void> clearAll() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      for (final String k in p.getKeys()) {
        if (k.startsWith(_prefix)) await p.remove(k);
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<_Entry?> _readEntry(String key) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_k(key));
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      return _Entry((m['t'] as num?)?.toInt() ?? 0, m['v']);
    } catch (_) {
      return null;
    }
  }
}

class _Entry {
  _Entry(this.t, this.v);
  final int t;
  final dynamic v;
}
