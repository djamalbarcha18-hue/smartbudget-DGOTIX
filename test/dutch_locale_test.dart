import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
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
  test('Dutch is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('nl'));
    expect(AppLang.nl.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.nl)));
  });

  test('categories, months and the Hijri calendar in Dutch', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.nl)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.nl), 'Wonen');
    expect(MonthNames.full(lang: AppLang.nl)[2], 'maart');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.nl),
        '1 Ramadan 1447 H.');
  });

  test('the privacy policy, terms and guide are Dutch, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.nl).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.nl).first.title, 'Overzicht');
  });

  test('Dutch defaults to the euro', () {
    expect(CurrencyDefaults.suggest(AppLang.nl), 'EUR');
    expect(
        CurrencyDefaults.suggest(AppLang.nl, country: 'be', deviceLanguage: 'nl'),
        'EUR');
  });

  group('quick entry in Dutch', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "gisteren" and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'koffie 3,5; trein 12 gisteren; salaris 2800; apotheek 9; huur 950',
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

    test('the longest word wins: "huurtoeslag" is income, "huur" housing', () {
      final QuickEntry? allowance =
          QuickEntryParser.parse('huurtoeslag 300', today: today);
      expect(allowance!.category, 'منحة أو إعانة');
      expect(allowance.type, TransactionType.income);
      expect(QuickEntryParser.parse('eergisteren boodschappen 40', today: today)!
          .date, DateTime(2026, 10, 12));
    });
  });
}
