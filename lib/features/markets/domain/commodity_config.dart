import 'package:flutter/foundation.dart';

import 'package:smartbudget/features/markets/domain/market_category.dart';

/// Static specification of a commodity/metal (configuration, NOT price data).
///
/// [providerId] selects which data provider serves this spec. 'gold_api' is a
/// live free source; anything else (or a category with no free source) resolves
/// to the "unavailable" provider until a licensed/backed source is wired.
@immutable
class CommoditySpec {
  const CommoditySpec({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.category,
    required this.unitLabel,
    required this.providerId,
    this.apiSymbol,
    this.benchmark,
    this.region,
    this.currency = 'USD',
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final MarketCategory category;
  final String unitLabel;
  final String providerId;
  final String? apiSymbol; // provider-specific symbol (e.g. gold-api 'XAU')
  final String? benchmark;
  final String? region;
  final String currency;
}

abstract final class CommodityConfig {
  static const List<CommoditySpec> all = <CommoditySpec>[
    // ---- Precious metals (live: gold-api.com, USD per troy ounce) ----
    CommoditySpec(code: 'XAU', nameEn: 'Gold', nameAr: 'الذهب', category: MarketCategory.preciousMetals, unitLabel: 'USD/oz', providerId: 'gold_api', apiSymbol: 'XAU'),
    CommoditySpec(code: 'XAG', nameEn: 'Silver', nameAr: 'الفضة', category: MarketCategory.preciousMetals, unitLabel: 'USD/oz', providerId: 'gold_api', apiSymbol: 'XAG'),
    CommoditySpec(code: 'XPT', nameEn: 'Platinum', nameAr: 'البلاتين', category: MarketCategory.preciousMetals, unitLabel: 'USD/oz', providerId: 'gold_api', apiSymbol: 'XPT'),
    CommoditySpec(code: 'XPD', nameEn: 'Palladium', nameAr: 'البلاديوم', category: MarketCategory.preciousMetals, unitLabel: 'USD/oz', providerId: 'gold_api', apiSymbol: 'XPD'),

    // ---- Industrial / base metals (LME reference — licensed → backend) ----
    CommoditySpec(code: 'XCU', nameEn: 'Copper', nameAr: 'النحاس', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'ALU', nameEn: 'Aluminium', nameAr: 'الألمنيوم', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'ZNC', nameEn: 'Zinc', nameAr: 'الزنك', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'NIK', nameEn: 'Nickel', nameAr: 'النيكل', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'LED', nameEn: 'Lead', nameAr: 'الرصاص', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'TIN', nameEn: 'Tin', nameAr: 'القصدير', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),
    CommoditySpec(code: 'COB', nameEn: 'Cobalt', nameAr: 'الكوبالت', category: MarketCategory.industrialMetals, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'LME'),

    // ---- Steel & Iron (Platts/LME/SGX benchmarks — licensed → backend) ----
    CommoditySpec(code: 'IORE62', nameEn: 'Iron Ore 62% Fe', nameAr: 'خام الحديد 62%', category: MarketCategory.steelIron, unitLabel: 'USD/dmt', providerId: 'unavailable', benchmark: 'Platts 62% Fe', region: 'CFR China'),
    CommoditySpec(code: 'IORE58', nameEn: 'Iron Ore 58% Fe', nameAr: 'خام الحديد 58%', category: MarketCategory.steelIron, unitLabel: 'USD/dmt', providerId: 'unavailable', benchmark: 'Platts 58% Fe', region: 'CFR China'),
    CommoditySpec(code: 'HRC', nameEn: 'Steel HRC', nameAr: 'صلب HRC', category: MarketCategory.steelIron, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'HRC'),
    CommoditySpec(code: 'REBAR', nameEn: 'Steel Rebar', nameAr: 'حديد التسليح', category: MarketCategory.steelIron, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'Rebar'),
    CommoditySpec(code: 'BILLET', nameEn: 'Steel Billet', nameAr: 'بيليت الصلب', category: MarketCategory.steelIron, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'Billet'),
    CommoditySpec(code: 'SCRAP', nameEn: 'Steel Scrap', nameAr: 'خردة الصلب', category: MarketCategory.steelIron, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'Scrap'),

    // ---- Energy (CME/ICE futures — licensed/keyed → backend) ----
    CommoditySpec(code: 'BRENT', nameEn: 'Brent Crude', nameAr: 'خام برنت', category: MarketCategory.energy, unitLabel: 'USD/bbl', providerId: 'unavailable', benchmark: 'ICE Brent'),
    CommoditySpec(code: 'WTI', nameEn: 'WTI Crude', nameAr: 'خام غرب تكساس', category: MarketCategory.energy, unitLabel: 'USD/bbl', providerId: 'unavailable', benchmark: 'NYMEX WTI'),
    CommoditySpec(code: 'NGAS', nameEn: 'Natural Gas', nameAr: 'الغاز الطبيعي', category: MarketCategory.energy, unitLabel: 'USD/MMBtu', providerId: 'unavailable', benchmark: 'Henry Hub'),

    // ---- Agriculture (CBOT/ICE futures — licensed/keyed → backend) ----
    CommoditySpec(code: 'WHEAT', nameEn: 'Wheat', nameAr: 'القمح', category: MarketCategory.agriculture, unitLabel: 'USd/bu', providerId: 'unavailable', benchmark: 'CBOT'),
    CommoditySpec(code: 'CORN', nameEn: 'Corn', nameAr: 'الذرة', category: MarketCategory.agriculture, unitLabel: 'USd/bu', providerId: 'unavailable', benchmark: 'CBOT'),
    CommoditySpec(code: 'SOYB', nameEn: 'Soybeans', nameAr: 'فول الصويا', category: MarketCategory.agriculture, unitLabel: 'USd/bu', providerId: 'unavailable', benchmark: 'CBOT'),
    CommoditySpec(code: 'SUGAR', nameEn: 'Sugar', nameAr: 'السكر', category: MarketCategory.agriculture, unitLabel: 'USd/lb', providerId: 'unavailable', benchmark: 'ICE'),
    CommoditySpec(code: 'COFFEE', nameEn: 'Coffee', nameAr: 'البن', category: MarketCategory.agriculture, unitLabel: 'USd/lb', providerId: 'unavailable', benchmark: 'ICE'),
    CommoditySpec(code: 'COCOA', nameEn: 'Cocoa', nameAr: 'الكاكاو', category: MarketCategory.agriculture, unitLabel: 'USD/t', providerId: 'unavailable', benchmark: 'ICE'),
  ];

  static List<CommoditySpec> byCategory(MarketCategory category) =>
      all.where((CommoditySpec s) => s.category == category).toList();
}
