import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exchange rates as "units per 1 USD" (USD = 1.0). Seeded from indicative V1
/// values; user-editable and persisted. These are indicative only until the
/// backend refreshes them from a live source (a later phase).
final ratesProvider =
    NotifierProvider<RatesController, Map<String, double>>(RatesController.new);

class RatesController extends Notifier<Map<String, double>> {
  static const String _key = 'sb_rates';

  /// Indicative defaults (mirror SmartBudget V1 CURRENCIES).
  static const Map<String, double> _seed = <String, double>{
    'USD': 1.0,
    'DZD': 134.5,
    'SAR': 3.75,
    'AED': 3.6725,
    'QAR': 3.64,
    'KWD': 0.31,
    'BHD': 0.376,
    'OMR': 0.3845,
    'EGP': 48.0,
    'JOD': 0.709,
    'TND': 3.15,
    'MAD': 9.95,
    'EUR': 0.92,
    'GBP': 0.79,
  };

  @override
  Map<String, double> build() {
    _load();
    return Map<String, double>.from(_seed);
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
        final Map<String, double> merged = Map<String, double>.from(_seed);
        m.forEach((String k, dynamic v) {
          final double? d = (v is num) ? v.toDouble() : double.tryParse('$v');
          if (d != null && d > 0) merged[k] = d;
        });
        state = merged;
      }
    } catch (_) {
      // Keep seed defaults.
    }
  }

  Future<void> setRate(String code, double rate) async {
    if (code == 'USD' || rate <= 0) return; // USD is the fixed reference
    state = <String, double>{...state, code: rate};
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state));
    } catch (_) {
      // Non-fatal.
    }
  }
}
