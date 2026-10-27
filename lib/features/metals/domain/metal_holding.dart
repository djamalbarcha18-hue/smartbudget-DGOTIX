import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// The precious metals a user can keep savings in.
enum Metal { gold, silver, platinum, palladium }

extension MetalX on Metal {
  /// The market symbol its price is quoted under (USD per troy ounce).
  String get symbol => switch (this) {
        Metal.gold => 'XAU',
        Metal.silver => 'XAG',
        Metal.platinum => 'XPT',
        Metal.palladium => 'XPD',
      };

  /// Gold in karats (24 = pure); the others in parts per thousand.
  List<int> get purities => switch (this) {
        Metal.gold => const <int>[24, 22, 21, 18, 14, 12, 10, 9],
        Metal.silver => const <int>[999, 958, 925, 900, 800],
        Metal.platinum => const <int>[999, 950, 900, 850],
        Metal.palladium => const <int>[999, 950, 500],
      };

  int get defaultPurity => switch (this) {
        Metal.gold => 21,
        Metal.silver => 925,
        Metal.platinum => 950,
        Metal.palladium => 950,
      };

  /// The share of pure metal in [purity] (21 karat = 0.875, 925 = 0.925).
  double fraction(int purity) =>
      this == Metal.gold ? purity / 24 : purity / 1000;

  static Metal? byName(String? name) {
    for (final Metal m in Metal.values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

/// One piece or bar of precious metal the user keeps as savings.
@immutable
class MetalHolding {
  const MetalHolding({
    required this.id,
    required this.metal,
    required this.grams,
    required this.purity,
    this.name = '',
    this.paid,
    this.paidBase,
    this.making,
    this.boughtOn,
    required this.createdAt,
  });

  final String id;
  final Metal metal;

  /// The weight as weighed (alloy included).
  final double grams;

  /// Karats for gold, parts per thousand for silver and platinum.
  final int purity;

  /// «Bracelet», «10 g bar»… optional.
  final String name;

  /// What it cost, in the currency paid (optional).
  final Money? paid;

  /// When [paid] is in another currency: what it came to in the user's
  /// currency at the time (so later exchange rates don't change the gain).
  final Money? paidBase;

  /// The part of [paid] that was workmanship (jewellery), same currency.
  final Money? making;
  final DateTime? boughtOn;
  final DateTime createdAt;

  /// Grams of pure metal in it.
  double get pureGrams => grams * metal.fraction(purity);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'metal': metal.name,
        'grams': grams,
        'purity': purity,
        if (name.isNotEmpty) 'name': name,
        if (paid != null) 'paidMinor': paid!.minorUnits,
        if (paid != null) 'paidCurrency': paid!.currencyCode,
        if (paidBase != null) 'paidBaseMinor': paidBase!.minorUnits,
        if (paidBase != null) 'paidBaseCurrency': paidBase!.currencyCode,
        if (making != null) 'makingMinor': making!.minorUnits,
        if (boughtOn != null) 'boughtOn': boughtOn!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory MetalHolding.fromJson(Map<String, dynamic> json) {
    final Metal metal = MetalX.byName(json['metal'] as String?) ?? Metal.gold;
    final int purity = (json['purity'] as num?)?.toInt() ?? 0;
    return MetalHolding(
      id: json['id'] as String,
      metal: metal,
      grams: (json['grams'] as num?)?.toDouble() ?? 0,
      purity: metal.purities.contains(purity) ? purity : metal.defaultPurity,
      name: (json['name'] as String?) ?? '',
      paid: json['paidMinor'] == null
          ? null
          : Money((json['paidMinor'] as num).toInt(),
              (json['paidCurrency'] as String?) ?? 'USD'),
      paidBase: json['paidBaseMinor'] is num &&
              json['paidBaseCurrency'] is String
          ? Money((json['paidBaseMinor'] as num).toInt(),
              json['paidBaseCurrency'] as String)
          : null,
      making: json['paidMinor'] != null && json['makingMinor'] is num
          ? Money((json['makingMinor'] as num).toInt(),
              (json['paidCurrency'] as String?) ?? 'USD')
          : null,
      boughtOn: DateTime.tryParse((json['boughtOn'] as String?) ?? ''),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime(2000),
    );
  }
}
