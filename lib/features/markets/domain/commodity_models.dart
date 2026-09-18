import 'package:flutter/foundation.dart';

import 'package:smartbudget/features/markets/domain/market_category.dart';

/// How fresh / authoritative a price is. Drives the quality badge and whether a
/// value is shown at all (unavailable → no number, never fabricated).
enum PriceQuality { realtime, nearRealtime, delayed, indicative, unavailable }

/// A single commodity/metal quote. Every price carries its unit, currency,
/// source, timestamp and quality; region/benchmark are set when the price is
/// regional or a named benchmark. Prices are optional — null means "no reliable
/// source yet" and the UI renders "unavailable".
@immutable
class CommodityQuote {
  const CommodityQuote({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.category,
    required this.unitLabel,
    required this.currency,
    required this.source,
    required this.updatedAt,
    required this.quality,
    this.priceUsd,
    this.previousUsd,
    this.benchmark,
    this.region,
    this.change24h,
    this.change7d,
    this.change30d,
    this.changeYtd,
    this.high52w,
    this.low52w,
  });

  final String code; // XAU, XCU, BRENT, WHEAT…
  final String nameEn;
  final String nameAr;
  final MarketCategory category;

  /// Canonical unit for this commodity (kept, never force-unified), e.g.
  /// 'USD/oz', 'USD/t', 'USD/bbl', 'USD/MMBtu', 'USD/bu'.
  final String unitLabel;
  final String currency; // pricing currency of [priceUsd]'s source (USD here)

  final double? priceUsd;
  final double? previousUsd;
  final String? benchmark; // e.g. 'Platts 62% Fe CFR China'
  final String? region; // e.g. 'CFR China', 'Henry Hub'

  // Optional analytics — populated only when a history source exists.
  final double? change24h;
  final double? change7d;
  final double? change30d;
  final double? changeYtd;
  final double? high52w;
  final double? low52w;

  final String source;
  final DateTime updatedAt;
  final PriceQuality quality;

  bool get hasPrice => priceUsd != null;

  /// Absolute change vs [previousUsd] when both are known.
  double? get change =>
      (priceUsd != null && previousUsd != null) ? priceUsd! - previousUsd! : null;

  double? get changePct => (change != null && previousUsd != null && previousUsd != 0)
      ? change! / previousUsd! * 100
      : null;
}
