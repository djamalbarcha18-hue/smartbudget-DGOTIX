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
    // Arab currencies (units per 1 USD).
    'DZD': 134.5,
    'SAR': 3.75,
    'AED': 3.6725,
    'QAR': 3.64,
    'KWD': 0.307,
    'BHD': 0.376,
    'OMR': 0.3845,
    'JOD': 0.709,
    'EGP': 48.0,
    'MAD': 9.95,
    'TND': 3.12,
    'LYD': 4.85,
    'IQD': 1310.0,
    'LBP': 89500.0,
    'SYP': 13000.0,
    'SDG': 600.0,
    'YER': 250.0,
    'MRU': 39.7,
    // Global currencies.
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 150.0,
    'CNY': 7.2,
    'CHF': 0.88,
    'CAD': 1.36,
    'AUD': 1.52,
    'INR': 83.3,
    'TRY': 34.0,
    'RUB': 92.0,
    'BRL': 5.4,
    'ZAR': 18.5,
    'SGD': 1.34,
    'KRW': 1350.0,
    'SEK': 10.6,
    'MXN': 18.5,
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
