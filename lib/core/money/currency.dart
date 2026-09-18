import 'package:flutter/foundation.dart';

/// A supported display currency.
///
/// `decimals` follows real ISO 4217 minor-unit conventions (e.g. KWD/BHD/OMR/
/// JOD/TND/LYD/IQD use 3; JPY/KRW use 0). Amounts everywhere are stored as
/// integer minor units + a currency code, so getting `decimals` right per
/// currency is required for correct money math.
///
/// `country` is the ISO 3166-1 alpha-2 code (lowercase) used to resolve the
/// bundled flag asset for quick visual switching.
@immutable
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameAr,
    required this.country,
    this.decimals = 2,
  });

  final String code;
  final String symbol;
  final String nameEn;
  final String nameAr;

  /// ISO 3166-1 alpha-2 (lowercase), e.g. 'sa', 'us', 'eu'.
  final String country;
  final int decimals;

  /// Bundled flag image for this currency's country/region.
  String get flagAsset => 'assets/flags/$country.png';

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

/// Built-in currency catalog. USD is the reference for exchange rates.
///
/// Covers the major Arab currencies and the major global currencies so the app
/// works as a global platform. Cross-currency conversion of transactions still
/// lands with the backend phase; this catalog + the converter cover display and
/// on-device conversion meanwhile.
abstract final class Currencies {
  static const Currency usd = Currency(
      code: 'USD', symbol: '\$', nameEn: 'US Dollar', nameAr: 'الدولار الأمريكي', country: 'us');

  static const List<Currency> all = <Currency>[
    // ---- Arab currencies ----
    Currency(code: 'DZD', symbol: 'د.ج', nameEn: 'Algerian Dinar', nameAr: 'الدينار الجزائري', country: 'dz'),
    Currency(code: 'SAR', symbol: 'ر.س', nameEn: 'Saudi Riyal', nameAr: 'الريال السعودي', country: 'sa'),
    Currency(code: 'AED', symbol: 'د.إ', nameEn: 'UAE Dirham', nameAr: 'الدرهم الإماراتي', country: 'ae'),
    Currency(code: 'QAR', symbol: 'ر.ق', nameEn: 'Qatari Riyal', nameAr: 'الريال القطري', country: 'qa'),
    Currency(code: 'KWD', symbol: 'د.ك', nameEn: 'Kuwaiti Dinar', nameAr: 'الدينار الكويتي', country: 'kw', decimals: 3),
    Currency(code: 'BHD', symbol: 'د.ب', nameEn: 'Bahraini Dinar', nameAr: 'الدينار البحريني', country: 'bh', decimals: 3),
    Currency(code: 'OMR', symbol: 'ر.ع', nameEn: 'Omani Rial', nameAr: 'الريال العماني', country: 'om', decimals: 3),
    Currency(code: 'JOD', symbol: 'د.أ', nameEn: 'Jordanian Dinar', nameAr: 'الدينار الأردني', country: 'jo', decimals: 3),
    Currency(code: 'EGP', symbol: 'ج.م', nameEn: 'Egyptian Pound', nameAr: 'الجنيه المصري', country: 'eg'),
    Currency(code: 'MAD', symbol: 'د.م', nameEn: 'Moroccan Dirham', nameAr: 'الدرهم المغربي', country: 'ma'),
    Currency(code: 'TND', symbol: 'د.ت', nameEn: 'Tunisian Dinar', nameAr: 'الدينار التونسي', country: 'tn', decimals: 3),
    Currency(code: 'LYD', symbol: 'د.ل', nameEn: 'Libyan Dinar', nameAr: 'الدينار الليبي', country: 'ly', decimals: 3),
    Currency(code: 'IQD', symbol: 'د.ع', nameEn: 'Iraqi Dinar', nameAr: 'الدينار العراقي', country: 'iq', decimals: 3),
    Currency(code: 'LBP', symbol: 'ل.ل', nameEn: 'Lebanese Pound', nameAr: 'الليرة اللبنانية', country: 'lb'),
    Currency(code: 'SYP', symbol: 'ل.س', nameEn: 'Syrian Pound', nameAr: 'الليرة السورية', country: 'sy'),
    Currency(code: 'SDG', symbol: 'ج.س', nameEn: 'Sudanese Pound', nameAr: 'الجنيه السوداني', country: 'sd'),
    Currency(code: 'YER', symbol: 'ر.ي', nameEn: 'Yemeni Rial', nameAr: 'الريال اليمني', country: 'ye'),
    Currency(code: 'MRU', symbol: 'أ.م', nameEn: 'Mauritanian Ouguiya', nameAr: 'الأوقية الموريتانية', country: 'mr'),

    // ---- Global currencies ----
    usd,
    Currency(code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'اليورو', country: 'eu'),
    Currency(code: 'GBP', symbol: '£', nameEn: 'Pound Sterling', nameAr: 'الجنيه الإسترليني', country: 'gb'),
    Currency(code: 'JPY', symbol: '¥', nameEn: 'Japanese Yen', nameAr: 'الين الياباني', country: 'jp', decimals: 0),
    Currency(code: 'CNY', symbol: '¥', nameEn: 'Chinese Yuan', nameAr: 'اليوان الصيني', country: 'cn'),
    Currency(code: 'CHF', symbol: 'Fr', nameEn: 'Swiss Franc', nameAr: 'الفرنك السويسري', country: 'ch'),
    Currency(code: 'CAD', symbol: 'C\$', nameEn: 'Canadian Dollar', nameAr: 'الدولار الكندي', country: 'ca'),
    Currency(code: 'AUD', symbol: 'A\$', nameEn: 'Australian Dollar', nameAr: 'الدولار الأسترالي', country: 'au'),
    Currency(code: 'INR', symbol: '₹', nameEn: 'Indian Rupee', nameAr: 'الروبية الهندية', country: 'in'),
    Currency(code: 'TRY', symbol: '₺', nameEn: 'Turkish Lira', nameAr: 'الليرة التركية', country: 'tr'),
    Currency(code: 'RUB', symbol: '₽', nameEn: 'Russian Ruble', nameAr: 'الروبل الروسي', country: 'ru'),
    Currency(code: 'BRL', symbol: 'R\$', nameEn: 'Brazilian Real', nameAr: 'الريال البرازيلي', country: 'br'),
    Currency(code: 'ZAR', symbol: 'R', nameEn: 'South African Rand', nameAr: 'الراند الجنوب إفريقي', country: 'za'),
    Currency(code: 'SGD', symbol: 'S\$', nameEn: 'Singapore Dollar', nameAr: 'الدولار السنغافوري', country: 'sg'),
    Currency(code: 'KRW', symbol: '₩', nameEn: 'South Korean Won', nameAr: 'الوون الكوري الجنوبي', country: 'kr', decimals: 0),
    Currency(code: 'SEK', symbol: 'kr', nameEn: 'Swedish Krona', nameAr: 'الكرونة السويدية', country: 'se'),
    Currency(code: 'MXN', symbol: 'Mex\$', nameEn: 'Mexican Peso', nameAr: 'البيزو المكسيكي', country: 'mx'),
  ];

  static Currency byCode(String code) =>
      all.firstWhere((Currency c) => c.code == code, orElse: () => usd);
}
