/// Remembers a written analysis so re-exporting the same report is free.
///
/// The commentary costs one of the account's assistant requests. Exporting
/// January twice — to read it, then to send it — should not cost two. The
/// cache is keyed by a digest of exactly what the assistant was given, so:
///
/// * the same period, the same figures and the same language answer from
///   disk, and no request is made at all;
/// * one new transaction, a changed budget or a different language changes
///   the digest, and a fresh analysis is written — a cached sentence about
///   figures that have moved would be worse than no sentence.
///
/// It lives on the device, in the app's own preferences. Nothing is sent
/// anywhere to store it, and it holds only text the assistant already
/// returned.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportInsightCache {
  const ReportInsightCache();

  static const String prefKey = 'report_insight_cache_v1';

  /// How many analyses are kept. Four periods across a couple of years is
  /// the realistic working set; past that the oldest is dropped.
  static const int keep = 12;

  /// The key for one analysis: everything that could change its text.
  ///
  /// [brief] is the exact payload sent to the assistant, so every figure in
  /// it is part of the key — there is no list of "fields that matter" to
  /// keep in step with the brief.
  static String keyFor({
    required String accountKey,
    required String language,
    required String periodLabel,
    required String brief,
  }) {
    final String raw =
        <String>[accountKey, language, periodLabel, brief].join('\u0000');
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 32);
  }

  Future<String?> read(String key) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, Object?> all = _decode(p.getString(prefKey));
      final Object? hit = all[key];
      if (hit is! Map) return null;
      final Object? text = hit['text'];
      return text is String && text.trim().isNotEmpty ? text : null;
    } catch (_) {
      // Storage unavailable or corrupt: the report is written as if there
      // were no cache, which costs a request and nothing else.
      return null;
    }
  }

  Future<void> write(String key, String text) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, Object?> all = _decode(p.getString(prefKey));
      all[key] = <String, Object?>{
        'text': text,
        'at': DateTime.now().toUtc().millisecondsSinceEpoch,
      };
      await p.setString(prefKey, jsonEncode(_trim(all)));
    } catch (_) {
      // Not being able to remember it is not a reason to lose it: the caller
      // already has the text.
    }
  }

  static Map<String, Object?> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    try {
      final Object? parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic>
          ? Map<String, Object?>.from(parsed)
          : <String, Object?>{};
    } catch (_) {
      return <String, Object?>{};
    }
  }

  /// Keeps the [keep] most recent entries, oldest dropped first.
  static Map<String, Object?> _trim(Map<String, Object?> all) {
    if (all.length <= keep) return all;
    int stamp(Object? e) => (e is Map && e['at'] is int) ? e['at']! as int : 0;
    final List<String> byAge = all.keys.toList()
      ..sort((String a, String b) => stamp(all[b]).compareTo(stamp(all[a])));
    return <String, Object?>{
      for (final String k in byAge.take(keep)) k: all[k],
    };
  }
}

final reportInsightCacheProvider =
    Provider<ReportInsightCache>((Ref ref) => const ReportInsightCache());
