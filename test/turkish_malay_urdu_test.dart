import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

// Completeness (strings, guide, legal) is checked for every language in
// languages_test.dart; this covers what is specific to these three.

void main() {
  final DateTime today = DateTime(2026, 10, 14);
  final DateTime yesterday = DateTime(2026, 10, 13);

  test('Urdu is written right to left; Turkish and Malay are not', () {
    expect(AppLang.ur.rtl, isTrue);
    expect(AppLang.tr.rtl, isFalse);
    expect(AppLang.ms.rtl, isFalse);
  });

  test('Turkish upper case keeps the dot on i', () {
    expect(AppLang.tr.upper('Planla ve biriktir'), 'PLANLA VE BİRİKTİR');
    expect(AppLang.en.upper('insights'), 'INSIGHTS');
  });

  test('categories, months and the Hijri calendar', () {
    expect(Catalog.label('السكن', lang: AppLang.tr), 'Konut');
    expect(Catalog.label('السكن', lang: AppLang.ms), 'Perumahan');
    expect(Catalog.label('السكن', lang: AppLang.ur), 'رہائش');
    expect(MonthNames.full(lang: AppLang.tr).first, 'Ocak');
    expect(MonthNames.full(lang: AppLang.ms)[2], 'Mac');
    expect(MonthNames.full(lang: AppLang.ur).first, 'جنوری');
    const HijriDate ramadan = HijriDate(1447, 9, 1);
    expect(ramadan.format(lang: AppLang.tr), '1 Ramazan 1447 H');
    expect(ramadan.format(lang: AppLang.ms), '1 Ramadan 1447 H');
    expect(ramadan.format(lang: AppLang.ur), '1 رمضان 1447 ہجری');
  });

  test('the ringgit and the Pakistani rupee are currencies', () {
    expect(Currencies.byCode('MYR').symbol, 'RM');
    expect(Currencies.byCode('PKR').decimals, 0);
    expect(Currencies.byCode('TRY').symbol, '₺');
  });

  group('quick entry in Turkish', () {
    test('everyday words, "dün" and Turkish letters', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'kahve 85; taksi 250 dün; Maaş 45000; İlaç 120',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
      ]);
      expect(all[1].date, yesterday);
      expect(all[2].type, TransactionType.income);
    });

    test('"bin" is a thousand, "1.250" is grouped, TL is the lira', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('kira 25 bin', today: today);
      expect(rent!.amount, 25000);
      expect(rent.category, 'السكن');
      expect(QuickEntryParser.parse('market 1.250', today: today)!.amount,
          1250);
      expect(QuickEntryParser.parse('benzin 900 TL', today: today)!.currency,
          'TRY');
    });
  });

  group('quick entry in Malay', () {
    test('everyday words and "semalam"', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'kopi 5; teksi 20 semalam; gaji 4200; klinik 50',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
      ]);
      expect(all[1].date, yesterday);
    });

    test('RM is the ringgit', () {
      final QuickEntry? e =
          QuickEntryParser.parse('nasi lemak RM12', today: today);
      expect(e!.amount, 12);
      expect(e.currency, 'MYR');
      expect(e.category, 'المطاعم');
    });
  });

  group('quick entry in Urdu', () {
    test('everyday words', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'چائے 150؛ رکشہ 300؛ تنخواہ 85000؛ دوائی 500',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
      ]);
      expect(all[2].type, TransactionType.income);
    });

    test('lakh, crore and lakh grouping', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('کرایہ مکان 1 لاکھ', today: today);
      expect(rent!.amount, 100000);
      expect(rent.category, 'السكن');
      expect(QuickEntryParser.parse('سبزی 2 hazar', today: today)!.amount,
          2000);
      expect(QuickEntryParser.parse('plot 1 crore', today: today)!.amount,
          10000000);
      expect(QuickEntryParser.parse('راشن 1,50,000', today: today)!.amount,
          150000);
    });

    test('roman Urdu "kal" and the rupee', () {
      final QuickEntry? milk =
          QuickEntryParser.parse('doodh 200 kal', today: today);
      expect(milk!.date, yesterday);
      expect(milk.category, 'الطعام');
      expect(QuickEntryParser.parse('دودھ 200 روپے', today: today)!.currency,
          'PKR');
    });

    test('Urdu spellings match Arabic keywords', () {
      // «قسط» is written the same; «زکوٰۃ» uses Urdu letters.
      expect(QuickEntryParser.parse('قسط 5000', today: today)!.category,
          'الأقساط والقروض');
      expect(QuickEntryParser.parse('زکوٰۃ 2500', today: today)!.category,
          'زكاة');
    });
  });

  test('Arabic entries still read the same', () {
    final QuickEntry? e =
        QuickEntryParser.parse('اشتراك كل شهر 500', today: today);
    expect(e!.date, today, reason: '«كل» is not a date word');
    expect(e.category, 'الاشتراكات');
  });
}
