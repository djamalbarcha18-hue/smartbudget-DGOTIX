import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What the scanner read for each recent photo, on this device, keyed by the
/// image's SHA-256: scanning the same photo again answers instantly and costs
/// no cloud scan. Only the reading is kept, never the image.
class ReceiptScanCache {
  ReceiptScanCache(this.userId);

  final String userId;

  static const int maxEntries = 30;

  String get _key => 'sb_receipt_cache_$userId';

  Future<List<Map<String, dynamic>>> _all() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[
        for (final Object? e in jsonDecode(raw) as List<dynamic>)
          if (e is Map) e.cast<String, dynamic>(),
      ];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _save(List<Map<String, dynamic>> entries) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(entries));
    } catch (_) {
      // A cache: losing it only costs a rescan.
    }
  }

  /// The reading stored for [hash], or null.
  Future<Map<String, dynamic>?> lookup(String hash) async {
    for (final Map<String, dynamic> e in await _all()) {
      if (e['h'] == hash && e['raw'] is Map) {
        return (e['raw'] as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  /// Remembers [raw] for [hash] (newest first, [maxEntries] at most).
  Future<void> store(String hash, Map<String, dynamic> raw) async {
    final List<Map<String, dynamic>> entries = await _all()
      ..removeWhere((Map<String, dynamic> e) => e['h'] == hash);
    entries.insert(0, <String, dynamic>{
      'h': hash,
      'at': DateTime.now().toIso8601String(),
      'raw': raw,
    });
    await _save(entries.take(maxEntries).toList());
  }

  /// Marks [hash] as added as an expense (used to spot duplicates).
  Future<void> markAdded(String hash) async {
    final List<Map<String, dynamic>> entries = await _all();
    for (final Map<String, dynamic> e in entries) {
      if (e['h'] == hash) e['added'] = true;
    }
    await _save(entries);
  }

  /// Readings of other photos that were added as expenses.
  Future<List<Map<String, dynamic>>> added({String? exceptHash}) async => <
      Map<String, dynamic>>[
    for (final Map<String, dynamic> e in await _all())
      if (e['added'] == true && e['h'] != exceptHash && e['raw'] is Map)
        (e['raw'] as Map).cast<String, dynamic>(),
  ];
}
