import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/metals/domain/metal_gains.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// Some or all of a piece, sold: the part sold (its weight and its share of
/// what the piece cost) and what was received for it.
@immutable
class MetalSale {
  const MetalSale({
    required this.id,
    required this.sold,
    required this.received,
    required this.soldOn,
    required this.createdAt,
    this.transactionId,
  });

  final String id;

  /// The part sold, as a piece of its own: its grams, and its share of the
  /// cost (paid, what it came to, workmanship). Its id is the piece's.
  final MetalHolding sold;
  final Money received;
  final DateTime soldOn;
  final DateTime createdAt;

  /// The income recorded with the sale, if the user asked for one.
  final String? transactionId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sold': sold.toJson(),
        'receivedMinor': received.minorUnits,
        'receivedCurrency': received.currencyCode,
        'soldOn': soldOn.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (transactionId != null) 'transactionId': transactionId,
      };

  factory MetalSale.fromJson(Map<String, dynamic> json) => MetalSale(
        id: json['id'] as String,
        sold: MetalHolding.fromJson(
            Map<String, dynamic>.from(json['sold'] as Map)),
        received: Money((json['receivedMinor'] as num).toInt(),
            json['receivedCurrency'] as String),
        soldOn: DateTime.parse(json['soldOn'] as String),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.parse(json['soldOn'] as String),
        transactionId: json['transactionId'] as String?,
      );
}

/// Selling part of a piece, and what selling earned.
abstract final class MetalSales {
  /// [h] cut in two: the [grams] sold and what is left (null when all of
  /// it is sold). Each part takes its share of the cost, so a piece keeps
  /// its price per gram; the shares always add up to the whole.
  static ({MetalHolding sold, MetalHolding? rest}) split(
      MetalHolding h, double grams) {
    if (grams >= h.grams - 1e-9) return (sold: h, rest: null);
    final double share = grams / h.grams;
    Money? part(Money? m) => m == null
        ? null
        : Money((m.minorUnits * share).round(), m.currencyCode);
    Money? left(Money? whole, Money? sold) => whole == null
        ? null
        : Money(whole.minorUnits - sold!.minorUnits, whole.currencyCode);
    final Money? paid = part(h.paid);
    final Money? paidBase = part(h.paidBase);
    final Money? making = part(h.making);
    MetalHolding piece(double g, Money? p, Money? b, Money? m) => MetalHolding(
          id: h.id,
          metal: h.metal,
          grams: g,
          purity: h.purity,
          name: h.name,
          paid: p,
          paidBase: b,
          making: m,
          boughtOn: h.boughtOn,
          createdAt: h.createdAt,
        );
    return (
      sold: piece(grams, paid, paidBase, making),
      rest: piece(h.grams - grams, left(h.paid, paid),
          left(h.paidBase, paidBase), left(h.making, making)),
    );
  }

  /// What came back when the sale is undone: the part sold joined to what
  /// is left of the piece ([rest], null when the piece is gone).
  static MetalHolding rejoin(MetalSale s, MetalHolding? rest) {
    if (rest == null) return s.sold;
    Money? sum(Money? a, Money? b) => a == null && b == null
        ? null
        : Money((a?.minorUnits ?? 0) + (b?.minorUnits ?? 0),
            (a ?? b)!.currencyCode);
    return MetalHolding(
      id: rest.id,
      metal: rest.metal,
      grams: rest.grams + s.sold.grams,
      purity: rest.purity,
      name: rest.name,
      paid: sum(rest.paid, s.sold.paid),
      paidBase: sum(rest.paidBase, s.sold.paidBase),
      making: sum(rest.making, s.sold.making),
      boughtOn: rest.boughtOn,
      createdAt: rest.createdAt,
    );
  }

  /// What [s] earned, in [currency]: what was received against the share
  /// of the cost sold. Null without a cost (or a rate).
  static Gain? gain(
      MetalSale s, String currency, Map<String, double> ratesVsUsd) {
    final Money? paid = MetalsValuation.cost(s.sold, currency, ratesVsUsd);
    final Money? got = WalletMath.convert(s.received, currency, ratesVsUsd);
    if (paid == null || got == null) return null;
    return Gain(paid: paid, value: got);
  }

  /// All that selling earned, in [currency] (sales with a known cost);
  /// null when there is none.
  static Gain? total(
      List<MetalSale> sales, String currency, Map<String, double> ratesVsUsd) {
    int paid = 0, got = 0;
    bool any = false;
    for (final MetalSale s in sales) {
      final Gain? g = gain(s, currency, ratesVsUsd);
      if (g == null) continue;
      any = true;
      paid += g.paid.minorUnits;
      got += g.value.minorUnits;
    }
    return any
        ? Gain(paid: Money(paid, currency), value: Money(got, currency))
        : null;
  }
}
