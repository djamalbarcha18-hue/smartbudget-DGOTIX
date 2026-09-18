import 'package:flutter/foundation.dart';

/// How a rate was priced. Also the user-selectable "Rate Type" for valuation.
enum MarketType { official, parallel, p2p, custom }

/// A FIAT quote for [currency] expressed in [baseCurrency], from one market.
///
/// A null [rate]/[buy]/[sell] means the data is NOT available for that market —
/// it is never fabricated. The UI renders "unavailable" for null values.
@immutable
class FxQuote {
  const FxQuote({
    required this.currency,
    required this.baseCurrency,
    required this.marketType,
    required this.source,
    required this.updatedAt,
    this.country,
    this.rate,
    this.buy,
    this.sell,
  });

  final String currency;
  final String baseCurrency;

  /// ISO country code for a country-specific (parallel) market, else null.
  final String? country;
  final MarketType marketType;

  /// Mid rate: [baseCurrency] units per 1 [currency] (e.g. DZD per 1 EUR).
  final double? rate;

  /// Parallel-market buy / sell (base units per 1 currency).
  final double? buy;
  final double? sell;

  final String source;
  final DateTime updatedAt;

  bool get hasData => rate != null || buy != null || sell != null;
}

/// A crypto asset quote (global USD + optional local-currency price).
///
/// [p2p], [buy], [sell] stay null until a reliable P2P source exists (backend),
/// so the UI shows "unavailable" rather than an invented number.
@immutable
class CryptoQuote {
  const CryptoQuote({
    required this.symbol,
    required this.name,
    required this.source,
    required this.updatedAt,
    this.usd,
    this.local,
    this.localCode,
    this.p2p,
    this.buy,
    this.sell,
    this.change24h,
    this.change7d,
    this.sparkline,
  });

  final String symbol; // BTC
  final String name; // Bitcoin
  final double? usd; // global price vs USD
  final double? local; // price in the user's base currency
  final String? localCode;
  final double? p2p;
  final double? buy;
  final double? sell;

  /// Percentage change over the last 24h / 7d (from the market source).
  final double? change24h;
  final double? change7d;

  /// 7-day price series for a sparkline (source currency = USD).
  final List<double>? sparkline;

  final String source;
  final DateTime updatedAt;

  bool get hasData => usd != null;
}

/// Snapshot of official mid-market FX rates expressed as units-per-USD.
@immutable
class FxSnapshot {
  const FxSnapshot({
    required this.ratesPerUsd,
    required this.updatedAt,
    required this.source,
  });

  final Map<String, double> ratesPerUsd; // 'DZD' -> DZD per 1 USD
  final DateTime updatedAt;
  final String source;

  /// Official cross rate: [base] units per 1 [currency] (e.g. DZD per 1 EUR).
  /// Returns null if either leg is missing.
  double? cross(String currency, String base) {
    final double? c = currency == 'USD' ? 1.0 : ratesPerUsd[currency];
    final double? b = base == 'USD' ? 1.0 : ratesPerUsd[base];
    if (c == null || b == null || c == 0) return null;
    return b / c;
  }

  /// Parses the open.er-api.com `/v6/latest/USD` response shape.
  static FxSnapshot fromErApi(Map<String, dynamic> json) {
    final Object? rates = json['rates'];
    final Map<String, double> parsed = <String, double>{};
    if (rates is Map) {
      rates.forEach((Object? k, Object? v) {
        final double? d = _asDouble(v);
        if (k is String && d != null) parsed[k] = d;
      });
    }
    final int? unix = _asInt(json['time_last_update_unix']);
    final DateTime updated = unix != null
        ? DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
        : DateTime.now().toUtc();
    return FxSnapshot(
      ratesPerUsd: parsed,
      updatedAt: updated,
      source: (json['provider'] as String?) ?? 'open.er-api.com',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rates': ratesPerUsd,
        'time_last_update_unix': updatedAt.millisecondsSinceEpoch ~/ 1000,
        'provider': source,
      };
}

double? _asDouble(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
int? _asInt(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

/// Shared numeric coercion used by the data-layer parsers.
double? asDoubleOrNull(Object? v) => _asDouble(v);
