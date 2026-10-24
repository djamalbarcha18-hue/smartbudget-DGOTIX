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
  test('Albanian is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('sq'));
    expect(AppLang.sq.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.sq)));
  });

  test('categories, months and the Hijri calendar in Albanian', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.sq)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.sq), 'Banesa');
    expect(MonthNames.full(lang: AppLang.sq)[10], 'nëntor');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.sq),
        '1 Ramazan 1447 H.');
  });

  test('the privacy policy, terms and guide are Albanian, not English', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.sq).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.sq).first.title, 'Përmbledhja');
  });

  test('the lek is a currency; Albania defaults to it, Kosovo to the euro', () {
    final Currency lek = Currencies.byCode('ALL');
    expect(lek.code, 'ALL');
    expect(lek.decimals, 0);
    expect(CurrencyDefaults.suggest(AppLang.sq), 'ALL');
    expect(CurrencyDefaults.forCountry('al'), 'ALL');
    expect(CurrencyDefaults.forCountry('xk'), 'EUR');
    expect(CurrencyDefaults.forCountry('me'), 'EUR');
    expect(
        CurrencyDefaults.suggest(AppLang.sq, country: 'xk', deviceLanguage: 'sq'),
        'EUR');
  });

  group('quick entry in Albanian', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "dje", ë and a decimal comma', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'kafe 1,5; byrek 2 dje; rroga 700; farmaci 9; qiraja 300',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'المطاعم',
        'راتب أساسي',
        'الصحة',
        'السكن',
      ]);
      expect(all[0].amount, 1.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('"mijë" is a thousand and "pardje" two days ago', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('qira 25 mijë pardje', today: today);
      expect(rent!.amount, 25000);
      expect(rent.date, DateTime(2026, 10, 12));
    });
  });
}
