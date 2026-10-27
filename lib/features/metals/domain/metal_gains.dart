import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/metals/domain/metal_history.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// Gain or loss on what was paid: [value] against [paid], same currency.
@immutable
class Gain {
  const Gain({required this.paid, required this.value});

  final Money paid;
  final Money value;

  Money get amount =>
      Money(value.minorUnits - paid.minorUnits, paid.currencyCode);

  /// As a share of what was paid (0.12 = +12%); null when nothing was paid.
  double? get ratio => paid.minorUnits <= 0
      ? null
      : (value.minorUnits - paid.minorUnits) / paid.minorUnits;

  bool get isGain => value.minorUnits >= paid.minorUnits;
}

/// One metal's purchases with a known cost: what a gram of the pure metal
/// cost on average, against today's price.
@immutable
class MetalAverage {
  const MetalAverage({
    required this.metal,
    required this.pureGrams,
    required this.paid,
    required this.todayPerGram,
  });

  final Metal metal;

  /// Pure grams in the purchases with a known cost.
  final double pureGrams;
  final Money paid;

  /// Today's price of a gram of the pure metal.
  final Money todayPerGram;

  /// What a gram of the pure metal cost on average.
  Money get paidPerGram =>
      Money.fromDouble(paid.asDouble / pureGrams, paid.currencyCode);
}

/// The purchases of one year (by purchase date, else the day added).
@immutable
class YearGain {
  const YearGain({required this.year, required this.gain, required this.count});

  final int year;
  final Gain gain;

  /// Purchases with a known cost that year.
  final int count;
}

/// Gains on precious metals bought at different times and prices. Each piece
/// or bar keeps its own cost, so nothing is averaged away: a piece bought
/// cheap long ago and one bought dear last month each show their own result,
/// and the totals add them up. Costs paid in another currency are converted
/// at the app's rates (today's).
abstract final class MetalGains {
  /// When [h] was bought (the day it was added when no date was given).
  static DateTime boughtOn(MetalHolding h) => h.boughtOn ?? h.createdAt;

  /// [h]'s cost in [currency], or null (no cost given, or no rate for it).
  static Money? cost(
          MetalHolding h, String currency, Map<String, double> ratesVsUsd) =>
      h.paid == null || h.paid!.minorUnits <= 0
          ? null
          : WalletMath.convert(h.paid!, currency, ratesVsUsd);

  /// [h]'s gain at [price], or null without a price or a cost.
  static Gain? ofHolding(
      MetalHolding h, MetalPrice? price, Map<String, double> ratesVsUsd) {
    if (price == null) return null;
    final Money? paid = cost(h, price.currency, ratesVsUsd);
    if (paid == null) return null;
    return Gain(paid: paid, value: MetalsValuation.value(h, price));
  }

  /// Per metal, the average cost of a pure gram over the purchases with a
  /// known cost (metals with none are left out).
  static Map<Metal, MetalAverage> averages(
    List<MetalHolding> holdings,
    Map<Metal, MetalPrice> prices,
    String currency,
    Map<String, double> ratesVsUsd,
  ) {
    final Map<Metal, double> grams = <Metal, double>{};
    final Map<Metal, int> paid = <Metal, int>{};
    for (final MetalHolding h in holdings) {
      final MetalPrice? p = prices[h.metal];
      if (p == null || p.currency != currency || h.pureGrams <= 0) continue;
      final Money? c = cost(h, currency, ratesVsUsd);
      if (c == null) continue;
      grams[h.metal] = (grams[h.metal] ?? 0) + h.pureGrams;
      paid[h.metal] = (paid[h.metal] ?? 0) + c.minorUnits;
    }
    return <Metal, MetalAverage>{
      for (final Metal m in grams.keys)
        m: MetalAverage(
          metal: m,
          pureGrams: grams[m]!,
          paid: Money(paid[m]!, currency),
          todayPerGram: Money.fromDouble(prices[m]!.perGram, currency),
        ),
    };
  }

  /// The purchases grouped by year, newest first (only those with a cost
  /// and a price).
  static List<YearGain> byYear(
    List<MetalHolding> holdings,
    Map<Metal, MetalPrice> prices,
    String currency,
    Map<String, double> ratesVsUsd,
  ) {
    final Map<int, int> paid = <int, int>{};
    final Map<int, int> value = <int, int>{};
    final Map<int, int> count = <int, int>{};
    for (final MetalHolding h in holdings) {
      final MetalPrice? p = prices[h.metal];
      if (p == null || p.currency != currency) continue;
      final Gain? g = ofHolding(h, p, ratesVsUsd);
      if (g == null) continue;
      final int y = boughtOn(h).year;
      paid[y] = (paid[y] ?? 0) + g.paid.minorUnits;
      value[y] = (value[y] ?? 0) + g.value.minorUnits;
      count[y] = (count[y] ?? 0) + 1;
    }
    final List<int> years = paid.keys.toList()..sort((a, b) => b.compareTo(a));
    return <YearGain>[
      for (final int y in years)
        YearGain(
          year: y,
          count: count[y]!,
          gain: Gain(
              paid: Money(paid[y]!, currency),
              value: Money(value[y]!, currency)),
        ),
    ];
  }

  /// How many holdings have no cost (left out of every gain).
  static int withoutCost(List<MetalHolding> holdings) => holdings
      .where((MetalHolding h) => h.paid == null || h.paid!.minorUnits <= 0)
      .length;

  /// What the market did over [points] (oldest first): the change in value
  /// less the money put in by buying meanwhile, so a purchase is never
  /// taken for a gain. Null unless both ends know what had been paid.
  /// The share is of what was at work: the value at the start plus the
  /// purchases since.
  static Gain? overPeriod(List<MetalPoint> points) {
    final List<MetalPoint> known = <MetalPoint>[
      for (final MetalPoint p in points)
        if (p.paid != null) p,
    ];
    if (known.length < 2) return null;
    final MetalPoint a = known.first, b = known.last;
    final int added = b.paid! - a.paid!;
    final int atWork = a.minor + added;
    if (atWork <= 0) return null;
    return Gain(
      paid: Money(atWork, b.currency),
      value: Money(b.minor, b.currency),
    );
  }
}
