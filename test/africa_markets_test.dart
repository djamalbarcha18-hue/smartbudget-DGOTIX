import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/currency_defaults.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

void main() {
  test('Nigeria, Kenya and South Africa count in their own currency', () {
    for (final (String country, String code) in <(String, String)>[
      ('NG', 'NGN'),
      ('KE', 'KES'),
      ('ZA', 'ZAR'),
    ]) {
      expect(
          CurrencyDefaults.suggest(AppLang.en,
              country: country, deviceLanguage: 'en'),
          code,
          reason: country);
    }
  });

  test('familiar wallets are suggested', () {
    List<String> names(String code) => WalletSuggestions.forCurrency(code)
        .map(((WalletType, String) s) => s.$2)
        .toList();
    expect(names('NGN'), contains('OPay'));
    expect(names('KES'), contains('M-Pesa'));
    expect(names('ZAR'), contains('Capitec'));
  });

  test('everyday words from the three markets', () {
    final List<QuickEntry> all = QuickEntryParser.parseAll(
        'matatu 100; airtime 50; suya 2000; tokens 1000; dstv 300; '
        'pick n pay 450',
        today: DateTime(2026, 10, 25));
    expect(all.map((QuickEntry e) => e.category).toList(), <String>[
      'النقل',
      'الاتصالات والإنترنت',
      'المطاعم',
      'الفواتير',
      'الاشتراكات',
      'الطعام',
    ]);
  });

  test('"boda" alone stays a Spanish wedding, not a motorbike taxi', () {
    expect(
        QuickEntryParser.parse('boda 500', today: DateTime(2026, 10, 25))!
            .category,
        isNot('النقل'));
  });
}
