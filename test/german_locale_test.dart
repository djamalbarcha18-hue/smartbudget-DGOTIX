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
  test('German is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('de'));
    expect(AppLang.de.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.de)));
  });

  test('categories, months and the Hijri calendar in German', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.de)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.de), 'Wohnen');
    expect(MonthNames.full(lang: AppLang.de)[2], 'März');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.de),
        '1. Ramadan 1447 n. H.');
  });

  test('the privacy policy, terms and guide are German, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.de).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.de).first.title, 'Übersicht');
  });

  test('a German phone defaults to the euro', () {
    expect(CurrencyDefaults.suggest(AppLang.de), 'EUR');
    expect(
        CurrencyDefaults.suggest(AppLang.de, country: 'ch', deviceLanguage: 'de'),
        'CHF');
  });

  group('quick entry in German', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "gestern", umlauts and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'Kaffee 3,5; Bahn 12 gestern; Gehalt 2800; Apotheke 8; Gemüse 6',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الطعام',
      ]);
      expect(all[0].amount, 3.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('"tsd" is a thousand and "Miete" is housing', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('Miete 1,2 tsd', today: today);
      expect(rent!.amount, 1200);
      expect(rent.category, 'السكن');
    });
  });
}
