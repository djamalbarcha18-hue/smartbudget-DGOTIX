import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/currency.dart';

/// The currency a new user most likely counts in, before they choose one:
/// their country's own (from the device region) when the app has it, else the
/// most common one for the app language.
abstract final class CurrencyDefaults {
  /// Countries that pay in euros (ISO 3166-1 alpha-2, lower case): the euro
  /// area, plus Kosovo and Montenegro, which use it without being members.
  static const Set<String> _euroArea = <String>{
    'at', 'be', 'cy', 'de', 'ee', 'es', 'fi', 'fr', 'gr', 'hr', 'ie', 'it', //
    'lt', 'lu', 'lv', 'mt', 'nl', 'pt', 'si', 'sk', 'xk', 'me',
  };

  /// The West African (XOF) and Central African (XAF) CFA franc countries.
  static const Set<String> _westAfricanCfa = <String>{
    'bj', 'bf', 'ci', 'gw', 'ml', 'ne', 'sn', 'tg',
  };
  static const Set<String> _centralAfricanCfa = <String>{
    'cm', 'cf', 'td', 'cg', 'gq', 'ga',
  };

  /// Currencies shown with a badge instead of a flag, by country.
  static const Map<String, String> _badged = <String, String>{
    'af': 'AFN',
    'tw': 'TWD',
  };

  /// With no usable region: the language's largest market, or the dollar
  /// where no single country stands for the language.
  static const Map<AppLang, String> _byLanguage = <AppLang, String>{
    AppLang.ar: 'SAR',
    AppLang.en: 'USD',
    AppLang.fr: 'EUR',
    AppLang.id: 'IDR',
    AppLang.es: 'EUR',
    AppLang.tr: 'TRY',
    AppLang.ms: 'MYR',
    AppLang.ur: 'PKR',
    AppLang.de: 'EUR',
    AppLang.pt: 'BRL',
    AppLang.it: 'EUR',
    AppLang.nl: 'EUR',
    AppLang.bs: 'BAM',
    AppLang.sq: 'ALL',
    AppLang.ru: 'RUB',
    AppLang.sw: 'KES',
    AppLang.ha: 'NGN',
    AppLang.zh: 'CNY',
    AppLang.hi: 'INR',
    AppLang.fa: 'IRR',
    AppLang.af: 'ZAR',
  };

  /// The currency of [country] (ISO 3166-1 alpha-2), or null when the app
  /// has none for it.
  static String? forCountry(String? country) {
    final String c = (country ?? '').toLowerCase();
    if (c.isEmpty) return null;
    if (_euroArea.contains(c)) return 'EUR';
    if (_westAfricanCfa.contains(c)) return 'XOF';
    if (_centralAfricanCfa.contains(c)) return 'XAF';
    if (_badged[c] case final String code) return code;
    for (final Currency cur in Currencies.all) {
      if (cur.country == c) return cur.code;
    }
    return null;
  }

  /// The currency for someone using the app in [lang]. The device's
  /// [country] wins only when the device is set to that same language
  /// ([deviceLanguage]), so a phone set to Mexican Spanish gets pesos while
  /// someone who picks Turkish in the app gets lira.
  static String suggest(AppLang lang, {String? country, String? deviceLanguage}) {
    if (deviceLanguage == null || deviceLanguage == lang.code) {
      final String? local = forCountry(country);
      if (local != null) return local;
    }
    return _byLanguage[lang] ?? Currencies.usd.code;
  }
}
