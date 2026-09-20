import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/markets/application/markets_controllers.dart';
import 'package:smartbudget/features/markets/domain/market_models.dart';

/// Live-FX status for the exchange-rates screen (never fabricated).
///
/// [liveCodes] are currencies whose value comes from the live mid-market feed,
/// [manualCodes] are currencies the user overrode by hand. Anything in neither
/// set is an indicative seed value.
class FxStatus {
  const FxStatus({
    this.loading = false,
    this.live = false,
    this.error = false,
    this.asOf,
    this.source,
    this.liveCodes = const <String>{},
    this.manualCodes = const <String>{},
  });

  final bool loading;
  final bool live;
  final bool error;
  final DateTime? asOf;
  final String? source;
  final Set<String> liveCodes;
  final Set<String> manualCodes;

  FxStatus copyWith({
    bool? loading,
    bool? live,
    bool? error,
    DateTime? asOf,
    String? source,
    Set<String>? liveCodes,
    Set<String>? manualCodes,
  }) =>
      FxStatus(
        loading: loading ?? this.loading,
        live: live ?? this.live,
        error: error ?? this.error,
        asOf: asOf ?? this.asOf,
        source: source ?? this.source,
        liveCodes: liveCodes ?? this.liveCodes,
        manualCodes: manualCodes ?? this.manualCodes,
      );
}

/// Live-FX status, published by [RatesController] and read by the UI.
final fxStatusProvider = StateProvider<FxStatus>((ref) => const FxStatus());

/// Exchange rates as "units per 1 USD" (USD = 1.0).
///
/// The map merges three layers, in increasing priority:
///   1. indicative seed defaults (offline-safe),
///   2. live mid-market rates from the keyless FX feed (open.er-api.com),
///   3. the user's manual overrides.
/// Live rates refresh on open (cached ~1h) and via a manual refresh; anything
/// the feed doesn't cover stays indicative rather than fabricated.
final ratesProvider =
    NotifierProvider<RatesController, Map<String, double>>(RatesController.new);

class RatesController extends Notifier<Map<String, double>> {
  /// Persisted user overrides (code -> rate). A dedicated key so we never
  /// mistake a full cached snapshot for hand-entered values.
  static const String _overridesKey = 'sb_rate_overrides';

  /// Persisted last-known live snapshot, for instant display before the network
  /// returns (and as an offline fallback).
  static const String _liveKey = 'sb_rate_live';

  Map<String, double> _overrides = <String, double>{};
  Map<String, double> _live = <String, double>{};

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
    // Kicks off async load + live refresh; state updates as data arrives.
    _init();
    return Map<String, double>.from(_seed);
  }

  Future<void> _init() async {
    await _loadOverrides();
    await _loadCachedLive();
    _recompute();
    await refresh();
  }

  /// Recomputes the merged rate map: seed < live < manual overrides.
  void _recompute() {
    final Map<String, double> merged = Map<String, double>.from(_seed);
    _live.forEach((String k, double v) {
      if (v > 0) merged[k] = v;
    });
    _overrides.forEach((String k, double v) {
      if (v > 0) merged[k] = v;
    });
    merged['USD'] = 1.0;
    state = merged;
  }

  Future<void> _loadOverrides() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_overridesKey);
      if (raw != null && raw.isNotEmpty) {
        _overrides = _parseRates(jsonDecode(raw));
      }
    } catch (_) {
      // Keep empty overrides.
    }
  }

  Future<void> _loadCachedLive() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_liveKey);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      _live = _parseRates(m['rates']);
      if (_live.isNotEmpty) {
        _publishStatus((FxStatus s) => s.copyWith(
              live: true,
              asOf: DateTime.tryParse('${m['asOf']}'),
              source: m['source'] as String?,
              liveCodes: _live.keys.toSet(),
              manualCodes: _overrides.keys.toSet(),
            ));
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Fetches fresh live rates. [force] bypasses the FX cache (manual refresh).
  Future<void> refresh({bool force = false}) async {
    _publishStatus((FxStatus s) => s.copyWith(loading: true, error: false));
    if (force) {
      await ref.read(rateCacheProvider).clearAll();
    }
    try {
      final FxSnapshot snap =
          await ref.read(fxRatesRepositoryProvider).latestVsUsd();
      _live = Map<String, double>.from(snap.ratesPerUsd)
        ..removeWhere((String k, double v) => v <= 0);
      await _persistLive(snap);
      _publishStatus((FxStatus s) => s.copyWith(
            loading: false,
            live: _live.isNotEmpty,
            error: false,
            asOf: snap.updatedAt,
            source: snap.source,
            liveCodes: _live.keys.toSet(),
            manualCodes: _overrides.keys.toSet(),
          ));
      _recompute();
    } catch (_) {
      // Keep whatever we have (cached live or indicative); flag the error.
      _publishStatus((FxStatus s) => s.copyWith(loading: false, error: true));
    }
  }

  /// Sets a manual override for [code] (USD is the fixed reference).
  Future<void> setRate(String code, double rate) async {
    if (code == 'USD' || rate <= 0) return;
    _overrides = <String, double>{..._overrides, code: rate};
    _recompute();
    _publishStatus(
        (FxStatus s) => s.copyWith(manualCodes: _overrides.keys.toSet()));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_overridesKey, jsonEncode(_overrides));
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Removes a manual override for [code], reverting to the live/indicative value.
  Future<void> clearOverride(String code) async {
    if (!_overrides.containsKey(code)) return;
    _overrides = <String, double>{..._overrides}..remove(code);
    _recompute();
    _publishStatus(
        (FxStatus s) => s.copyWith(manualCodes: _overrides.keys.toSet()));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_overridesKey, jsonEncode(_overrides));
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> _persistLive(FxSnapshot snap) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _liveKey,
        jsonEncode(<String, dynamic>{
          'rates': _live,
          'asOf': snap.updatedAt.toIso8601String(),
          'source': snap.source,
        }),
      );
    } catch (_) {
      // Non-fatal.
    }
  }

  void _publishStatus(FxStatus Function(FxStatus) update) {
    final StateController<FxStatus> ctrl = ref.read(fxStatusProvider.notifier);
    ctrl.state = update(ctrl.state);
  }

  static Map<String, double> _parseRates(Object? raw) {
    final Map<String, double> out = <String, double>{};
    if (raw is Map) {
      raw.forEach((Object? k, Object? v) {
        final double? d = (v is num) ? v.toDouble() : double.tryParse('$v');
        if (k is String && d != null && d > 0) out[k] = d;
      });
    }
    return out;
  }
}
