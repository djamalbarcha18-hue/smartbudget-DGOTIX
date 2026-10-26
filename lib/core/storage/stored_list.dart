import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Reads a list kept as JSON in SharedPreferences without ever losing it.
///
/// An entry that can't be read is left out on its own, instead of the whole
/// list being dropped. And when anything couldn't be read, the stored text
/// is first copied aside ([asideKey]; the first such copy is kept),
/// so the next save of the readable part can't destroy the only copy of the
/// rest.
abstract final class StoredList {
  static List<T> read<T>(
    SharedPreferences prefs,
    String key,
    String raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    final List<T> out = <T>[];
    bool lost = decoded is! List;
    if (decoded is List) {
      for (final Object? e in decoded) {
        try {
          if (e is Map) {
            out.add(fromJson(e.cast<String, dynamic>()));
          } else {
            lost = true;
          }
        } catch (_) {
          lost = true;
        }
      }
    }
    if (lost) keepAside(prefs, key, raw);
    return out;
  }

  /// The key the unreadable copy of [key] is kept under. It keeps the
  /// account suffix (`sb_unreadable_txns_<account>`), so deleting the
  /// account from the device removes it too (AccountKeys.ownerOf).
  static String asideKey(String key) => key.startsWith('sb_')
      ? 'sb_unreadable_${key.substring(3)}'
      : '$key.unreadable';

  static void keepAside(SharedPreferences prefs, String key, String raw) {
    final String aside = asideKey(key);
    if (prefs.getString(aside) != null) return;
    prefs.setString(aside, raw).catchError((Object _) => false);
  }
}
