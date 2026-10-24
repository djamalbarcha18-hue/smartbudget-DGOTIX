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

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

void main() {
  test('Bosnian is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('bs'));
    expect(AppLang.bs.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.bs)));
  });

  test('categories, months and the Hijri calendar in Bosnian', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.bs)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.bs), 'Stanovanje');
    expect(MonthNames.full(lang: AppLang.bs)[2], 'mart');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.bs),
        '1. Ramazan 1447. h. g.');
  });

  test('the privacy policy, terms and guide are Bosnian, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.bs).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.bs).first.title, 'Pregled');
  });

  test('the convertible mark is a currency, and Bosnian defaults to it', () {
    final Currency bam = Currencies.byCode('BAM');
    expect(bam.code, 'BAM');
    expect(bam.symbol, 'KM');
    expect(CurrencyDefaults.suggest(AppLang.bs), 'BAM');
    expect(CurrencyDefaults.forCountry('ba'), 'BAM');
  });

  group('quick entry in Bosnian', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "jučer", č/ć/š and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'kafa 2,5; ćevapi 12 jučer; plata 1800; apoteka 9; kirija 400',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'المطاعم',
        'راتب أساسي',
        'الصحة',
        'السكن',
      ]);
      expect(all[0].amount, 2.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('"hiljada" is a thousand; phone credit is not a loan', () {
      expect(QuickEntryParser.parse('rata 2 hiljade', today: today)!.amount,
          2000);
      expect(QuickEntryParser.parse('kredit za mobitel 20', today: today)!
          .category, 'الاتصالات والإنترنت');
      expect(QuickEntryParser.parse('namještaj 3 hiljada', today: today)!
          .amount, 3000);
    });
  });
}
