import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/markets/domain/metals_calculator.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// Where a metal's price comes from.
enum MetalPriceSource {
  /// The world market (spot), converted to the user's currency.
  market,

  /// The price per gram the user entered for their local market.
  mine,
}

/// The price of one gram of the pure metal, in [currency].
@immutable
class MetalPrice {
  const MetalPrice({
    required this.perGram,
    required this.currency,
    required this.source,
    this.updatedAt,
  });

  final double perGram;
  final String currency;
  final MetalPriceSource source;

  /// When the market quote was taken (null for the user's own price).
  final DateTime? updatedAt;

  /// The price per gram at [purity] («21 karat»).
  double at(Metal metal, int purity) => perGram * metal.fraction(purity);
}

/// What the user's metals are worth, per metal and in all.
@immutable
class MetalsSummary {
  const MetalsSummary({
    required this.total,
    required this.byMetal,
    required this.pureGrams,
    required this.unpriced,
    required this.paidTotal,
  });

  /// The value of every priced holding.
  final Money total;
  final Map<Metal, Money> byMetal;

  /// Grams of pure metal held, per metal.
  final Map<Metal, double> pureGrams;

  /// Metals held that have no price yet (offline on first use).
  final Set<Metal> unpriced;

  /// What the priced holdings with a known cost cost, in the same currency
  /// (null when none has one): the base for the gain or loss.
  final ({Money paid, Money value})? paidTotal;

  bool get isEmpty => pureGrams.isEmpty;
}

/// Pure valuation math (no I/O): world prices to the user's currency, and
/// holdings to their value.
abstract final class MetalsValuation {
  /// The market price of a gram of pure [metal] in [currency], from its
  /// price in US dollars per troy ounce and the app's rates (units per 1
  /// USD). Null when either is missing.
  static double? marketPerGram(
    double? usdPerOunce,
    String currency,
    Map<String, double> ratesVsUsd,
  ) {
    if (usdPerOunce == null || usdPerOunce <= 0) return null;
    final double? rate = currency == 'USD' ? 1 : ratesVsUsd[currency];
    if (rate == null || rate <= 0) return null;
    return MetalsCalculator.perGram(usdPerOunce) * rate;
  }

  /// [h]'s value at [price], in the price's currency.
  static Money value(MetalHolding h, MetalPrice price) =>
      Money.fromDouble(h.grams * price.at(h.metal, h.purity), price.currency);

  static MetalsSummary summarize(
    List<MetalHolding> holdings,
    Map<Metal, MetalPrice> prices,
    String currency,
    Map<String, double> ratesVsUsd,
  ) {
    int total = 0;
    final Map<Metal, int> byMetal = <Metal, int>{};
    final Map<Metal, double> grams = <Metal, double>{};
    final Set<Metal> unpriced = <Metal>{};
    int paid = 0;
    int paidValue = 0;
    bool anyPaid = false;
    for (final MetalHolding h in holdings) {
      grams[h.metal] = (grams[h.metal] ?? 0) + h.pureGrams;
      final MetalPrice? p = prices[h.metal];
      if (p == null || p.currency != currency) {
        unpriced.add(h.metal);
        continue;
      }
      final Money v = value(h, p);
      total += v.minorUnits;
      byMetal[h.metal] = (byMetal[h.metal] ?? 0) + v.minorUnits;
      final Money? cost = h.paid == null
          ? null
          : WalletMath.convert(h.paid!, currency, ratesVsUsd);
      if (cost != null) {
        anyPaid = true;
        paid += cost.minorUnits;
        paidValue += v.minorUnits;
      }
    }
    return MetalsSummary(
      total: Money(total, currency),
      byMetal: <Metal, Money>{
        for (final MapEntry<Metal, int> e in byMetal.entries)
          e.key: Money(e.value, currency),
      },
      pureGrams: grams,
      unpriced: unpriced,
      paidTotal: anyPaid
          ? (paid: Money(paid, currency), value: Money(paidValue, currency))
          : null,
    );
  }
}
