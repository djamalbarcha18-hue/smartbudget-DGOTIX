import 'package:flutter/foundation.dart';

/// A supported display currency. Mirrors the SmartBudget V1 currency set.
///
/// `decimals` follows real minor-unit conventions (e.g. KWD/BHD/OMR/TND use 3).
/// Amounts everywhere are stored as integer minor units + a currency code.
@immutable
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameAr,
    this.decimals = 2,
  });

  final String code;
  final String symbol;
  final String nameEn;
  final String nameAr;
  final int decimals;

  int get minorPerUnit {
    var m = 1;
    for (var i = 0; i < decimals; i++) {
      m *= 10;
    }
    return m;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Built-in currency catalog (subset of V1 `CURRENCIES`). USD is the reference.
abstract final class Currencies {
  static const Currency usd =
      Currency(code: 'USD', symbol: '\$', nameEn: 'US Dollar', nameAr: 'الدولار الأمريكي');

  static const List<Currency> all = <Currency>[
    Currency(code: 'DZD', symbol: 'د.ج', nameEn: 'Algerian Dinar', nameAr: 'الدينار الجزائري'),
    Currency(code: 'SAR', symbol: 'ر.س', nameEn: 'Saudi Riyal', nameAr: 'الريال السعودي'),
    Currency(code: 'AED', symbol: 'د.إ', nameEn: 'UAE Dirham', nameAr: 'الدرهم الإماراتي'),
    Currency(code: 'QAR', symbol: 'ر.ق', nameEn: 'Qatari Riyal', nameAr: 'الريال القطري'),
    Currency(code: 'KWD', symbol: 'د.ك', nameEn: 'Kuwaiti Dinar', nameAr: 'الدينار الكويتي', decimals: 3),
    Currency(code: 'BHD', symbol: 'د.ب', nameEn: 'Bahraini Dinar', nameAr: 'الدينار البحريني', decimals: 3),
    Currency(code: 'OMR', symbol: 'ر.ع', nameEn: 'Omani Rial', nameAr: 'الريال العماني', decimals: 3),
    Currency(code: 'EGP', symbol: 'ج.م', nameEn: 'Egyptian Pound', nameAr: 'الجنيه المصري'),
    Currency(code: 'JOD', symbol: 'د.أ', nameEn: 'Jordanian Dinar', nameAr: 'الدينار الأردني'),
    Currency(code: 'TND', symbol: 'د.ت', nameEn: 'Tunisian Dinar', nameAr: 'الدينار التونسي', decimals: 3),
    Currency(code: 'MAD', symbol: 'د.م', nameEn: 'Moroccan Dirham', nameAr: 'الدرهم المغربي'),
    Currency(code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'اليورو'),
    usd,
    Currency(code: 'GBP', symbol: '£', nameEn: 'Pound Sterling', nameAr: 'الجنيه الإسترليني'),
  ];

  static Currency byCode(String code) =>
      all.firstWhere((Currency c) => c.code == code, orElse: () => usd);
}
