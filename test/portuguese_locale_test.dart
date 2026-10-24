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
  test('Portuguese is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('pt'));
    expect(AppLang.pt.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.pt)));
  });

  test('categories, months and the Hijri calendar in Portuguese', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.pt)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.pt), 'Moradia');
    expect(MonthNames.full(lang: AppLang.pt)[2], 'março');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.pt),
        '1 de Ramadã de 1447 H');
  });

  test('the privacy policy, terms and guide are Portuguese, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.pt).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.pt).first.title, 'Painel');
  });

  test('Portuguese defaults to the real; a phone in Portugal to the euro', () {
    expect(CurrencyDefaults.suggest(AppLang.pt), 'BRL');
    expect(
        CurrencyDefaults.suggest(AppLang.pt, country: 'pt', deviceLanguage: 'pt'),
        'EUR');
  });

  group('quick entry in Portuguese', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "ontem", accents and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'pão 7,5; ônibus 4,4 ontem; salário 3200; farmácia 30; aluguel 1500',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'الطعام',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'السكن',
      ]);
      expect(all[0].amount, 7.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('the longest phrase wins: "passagem aérea" is travel', () {
      expect(QuickEntryParser.parse('passagem aérea 900', today: today)!.category,
          'السفر');
      expect(QuickEntryParser.parse('passagem 4,4', today: today)!.category,
          'النقل');
    });
  });
}
