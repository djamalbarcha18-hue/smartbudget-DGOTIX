import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A user-entered parallel ("street") rate for one currency pair in one country.
/// Per-viewer and stored locally — shown honestly as "manual", never mixed up
/// with a live feed.
class ManualParallel {
  const ManualParallel({this.buy, this.sell, required this.updatedAt});
  final double? buy;
  final double? sell;
  final DateTime updatedAt;

  bool get isEmpty => buy == null && sell == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (buy != null) 'buy': buy,
        if (sell != null) 'sell': sell,
        'at': updatedAt.toIso8601String(),
      };

  static ManualParallel? fromJson(Object? o) {
    if (o is! Map) return null;
    double? d(Object? v) => (v is num) ? v.toDouble() : null;
    final ManualParallel e = ManualParallel(
      buy: d(o['buy']),
      sell: d(o['sell']),
      updatedAt: DateTime.tryParse('${o['at']}') ?? DateTime.now(),
    );
    return e.isEmpty ? null : e;
  }
}

/// Composite key for a country + currency pair (e.g. `dz|EUR`).
String manualParallelKey(String country, String currency) =>
    '$country|$currency';

/// Holds all manually-entered parallel rates, persisted locally.
final manualParallelProvider =
    NotifierProvider<ManualParallelController, Map<String, ManualParallel>>(
        ManualParallelController.new);

class ManualParallelController extends Notifier<Map<String, ManualParallel>> {
  static const String _key = 'sb_manual_parallel';

  @override
  Map<String, ManualParallel> build() {
    _load();
    return const <String, ManualParallel>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final Map<String, ManualParallel> out = <String, ManualParallel>{};
      decoded.forEach((Object? k, Object? v) {
        final ManualParallel? e = ManualParallel.fromJson(v);
        if (k is String && e != null) out[k] = e;
      });
      if (out.isNotEmpty) state = out;
    } catch (_) {
      // Keep empty.
    }
  }

  /// Sets (or clears, when both are null) the manual rate for a pair.
  Future<void> setRate({
    required String country,
    required String currency,
    double? buy,
    double? sell,
  }) async {
    final String k = manualParallelKey(country, currency);
    final Map<String, ManualParallel> next =
        Map<String, ManualParallel>.from(state);
    final double? b = (buy != null && buy > 0) ? buy : null;
    final double? s = (sell != null && sell > 0) ? sell : null;
    if (b == null && s == null) {
      next.remove(k);
    } else {
      next[k] = ManualParallel(buy: b, sell: s, updatedAt: DateTime.now());
    }
    state = next;
    await _persist();
  }

  Future<void> clear(String country, String currency) =>
      setRate(country: country, currency: currency);

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> json = <String, dynamic>{
        for (final MapEntry<String, ManualParallel> e in state.entries)
          e.key: e.value.toJson(),
      };
      await p.setString(_key, jsonEncode(json));
    } catch (_) {
      // Non-fatal.
    }
  }
}
