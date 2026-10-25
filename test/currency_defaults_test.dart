import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/currency_defaults.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';

Future<ProviderContainer> _loaded(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final ProviderContainer c = ProviderContainer();
  c.read(baseCurrencyProvider);
  while (!c.read(baseCurrencyLoadedProvider)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return c;
}

void main() {
  test('each language suggests its own currency', () {
    expect(CurrencyDefaults.suggest(AppLang.tr), 'TRY');
    expect(CurrencyDefaults.suggest(AppLang.ms), 'MYR');
    expect(CurrencyDefaults.suggest(AppLang.ur), 'PKR');
    expect(CurrencyDefaults.suggest(AppLang.id), 'IDR');
    expect(CurrencyDefaults.suggest(AppLang.fr), 'EUR');
    expect(CurrencyDefaults.suggest(AppLang.en), 'USD');
    expect(CurrencyDefaults.suggest(AppLang.ar), 'SAR');
  });

  test('the device country wins when the device speaks that language', () {
    expect(
        CurrencyDefaults.suggest(AppLang.es,
            country: 'MX', deviceLanguage: 'es'),
        'MXN');
    expect(
        CurrencyDefaults.suggest(AppLang.ar,
            country: 'AE', deviceLanguage: 'ar'),
        'AED');
    expect(
        CurrencyDefaults.suggest(AppLang.fr,
            country: 'BE', deviceLanguage: 'fr'),
        'EUR');
    // Picking Turkish in the app on an Arabic phone: lira.
    expect(
        CurrencyDefaults.suggest(AppLang.tr,
            country: 'SA', deviceLanguage: 'ar'),
        'TRY');
    // A country the app has no currency for: the language's.
    expect(
        CurrencyDefaults.suggest(AppLang.en,
            country: 'IS', deviceLanguage: 'en'),
        'USD');
  });

  test('a new user gets the suggestion, which follows the language', () async {
    final ProviderContainer c = await _loaded(<String, Object>{
      'flutter.sb_locale': 'tr',
    });
    expect(c.read(baseCurrencyProvider), 'TRY');
    final BaseCurrencyController ctl = c.read(baseCurrencyProvider.notifier);
    expect(ctl.isChosen, isFalse);
    ctl.followLanguage(AppLang.ur);
    expect(c.read(baseCurrencyProvider), 'PKR');
    // Not saved: it is only a suggestion.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sb_base_currency'), isNull);
  });

  test('a chosen currency never follows the language', () async {
    final ProviderContainer c = await _loaded(<String, Object>{
      'flutter.sb_locale': 'tr',
      'flutter.sb_base_currency': 'EUR',
    });
    expect(c.read(baseCurrencyProvider), 'EUR');
    c.read(baseCurrencyProvider.notifier).followLanguage(AppLang.ms);
    expect(c.read(baseCurrencyProvider), 'EUR');
  });

  test('the first transaction keeps the suggestion for good', () async {
    final ProviderContainer c = await _loaded(<String, Object>{
      'flutter.sb_locale': 'ms',
    });
    final BaseCurrencyController ctl = c.read(baseCurrencyProvider.notifier);
    await ctl.keep();
    expect(ctl.isChosen, isTrue);
    ctl.followLanguage(AppLang.tr);
    expect(c.read(baseCurrencyProvider), 'MYR');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sb_base_currency'), 'MYR');
  });

  test('earlier users with data keep the dollar', () async {
    final ProviderContainer c = await _loaded(<String, Object>{
      'flutter.sb_locale': 'tr',
      'flutter.sb_txns_guest': '[]',
    });
    expect(c.read(baseCurrencyProvider), 'USD');
    expect(c.read(baseCurrencyProvider.notifier).isChosen, isTrue);
  });

  test('phones in newly added countries get their own currency', () {
    for (final (String country, String code) in <(String, String)>[
      ('ng', 'NGN'),
      ('ke', 'KES'),
      ('gh', 'GHS'),
      ('sn', 'XOF'),
      ('ci', 'XOF'),
      ('cm', 'XAF'),
      ('ga', 'XAF'),
      ('nz', 'NZD'),
      ('by', 'BYN'),
      ('vn', 'VND'),
      ('th', 'THB'),
      ('ph', 'PHP'),
      ('pl', 'PLN'),
      ('cz', 'CZK'),
      ('hu', 'HUF'),
      ('ir', 'IRR'),
      ('af', 'AFN'),
      ('hk', 'HKD'),
      ('tw', 'TWD'),
    ]) {
      expect(CurrencyDefaults.forCountry(country), code, reason: country);
    }
    // A French-speaking phone in Senegal counts in CFA francs, not euros.
    expect(
        CurrencyDefaults.suggest(AppLang.fr,
            country: 'SN', deviceLanguage: 'fr'),
        'XOF');
  });
}
