import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/currency_defaults.dart';
import 'package:smartbudget/features/guide/domain/guide_content.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';
import 'package:smartbudget/l10n/gen/app_localizations_ru.dart';

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

void main() {
  test('Russian is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('ru'));
    expect(AppLang.ru.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.ru)));
  });

  test('Russian plurals: 1 день, 2 дня, 5 дней, 21 день', () {
    final AppLocalizationsRu l = AppLocalizationsRu();
    expect(l.chDays(1), '1 день');
    expect(l.chDays(2), '2 дня');
    expect(l.chDays(5), '5 дней');
    expect(l.chDays(21), '21 день');
    expect(l.daretTurnIn(0), 'Ваша очередь сегодня');
    expect(l.daretTurnIn(1), 'Ваша очередь через 1 день');
    expect(l.daretTurnIn(11), 'Ваша очередь через 11 дней');
  });

  test('categories, months and the Hijri calendar in Russian', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.ru)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.ru), 'Жильё');
    expect(MonthNames.full(lang: AppLang.ru)[9], 'Октябрь');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.ru),
        '1 Рамадан 1447 г. х.');
  });

  test('the privacy policy, terms and guide are Russian, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.ru).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.ru).first.title, 'Обзор');
  });

  test('Central Asian currencies: each country gets its own', () {
    for (final (String country, String code, int decimals)
        in <(String, String, int)>[
      ('kz', 'KZT', 0),
      ('uz', 'UZS', 0),
      ('kg', 'KGS', 2),
      ('tj', 'TJS', 2),
      ('az', 'AZN', 2),
    ]) {
      expect(Currencies.byCode(code).decimals, decimals, reason: code);
      expect(CurrencyDefaults.forCountry(country), code);
    }
    expect(CurrencyDefaults.suggest(AppLang.ru), 'RUB');
    // A Russian-language phone in Kazakhstan counts in tenge.
    expect(
        CurrencyDefaults.suggest(AppLang.ru,
            country: 'kz', deviceLanguage: 'ru'),
        'KZT');
  });

  group('quick entry in Russian', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "вчера" and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'кофе 3,5; такси 12 вчера; зарплата 4200; аптека 9; аренда 300',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'السكن',
      ]);
      expect(all[0].amount, 3.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('"тыс" is a thousand, "позавчера" two days ago, ё reads as е', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('квартплата 25 тыс позавчера', today: today);
      expect(rent!.amount, 25000);
      expect(rent.date, DateTime(2026, 10, 12));
      expect(QuickEntryParser.parse('пятёрочка 800', today: today)!.category,
          'الطعام');
    });

    test('a currency named in Russian', () {
      expect(QuickEntryParser.parse('такси 2000 тенге', today: today)!.currency,
          'KZT');
      expect(QuickEntryParser.parse('обед 500 рублей', today: today)!.currency,
          'RUB');
    });

    test('"som" stays a Portuguese word, not a currency', () {
      expect(
          QuickEntryParser.parse('aparelho de som 300', today: today)!.currency,
          isNull);
    });
  });
}
