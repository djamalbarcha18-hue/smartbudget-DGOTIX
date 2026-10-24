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
  test('Italian is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('it'));
    expect(AppLang.it.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.it)));
  });

  test('categories, months and the Hijri calendar in Italian', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.it)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.it), 'Casa');
    expect(Catalog.label('أرباح تجارية', lang: AppLang.it), "Utili d'impresa");
    expect(MonthNames.full(lang: AppLang.it)[5], 'giugno');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.it),
        '1 Ramadan 1447 E.');
  });

  test('the privacy policy, terms and guide are Italian, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.it).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.it).first.title, 'Panoramica');
  });

  test('Italian defaults to the euro; a phone in Switzerland to the franc', () {
    expect(CurrencyDefaults.suggest(AppLang.it), 'EUR');
    expect(
        CurrencyDefaults.suggest(AppLang.it, country: 'ch', deviceLanguage: 'it'),
        'CHF');
  });

  group('quick entry in Italian', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "ieri", accents and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'caffè 1,5; treno 12 ieri; stipendio 2200; farmacia 9; affitto 750',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'السكن',
      ]);
      expect(all[0].amount, 1.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test("\"l'altro ieri\" is two days ago", () {
      expect(
          QuickEntryParser.parse("pizzeria 30 l'altro ieri", today: today)!.date,
          DateTime(2026, 10, 12));
    });
  });
}
