import 'package:flutter/material.dart';
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

void main() {
  test('hi is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('hi'));
    expect(AppLang.hi.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.hi)));
    // The PDF library can't join Devanagari: reports are in English.
    expect(AppLang.hi.pdfInEnglish, isTrue);
    expect(AppLang.ar.pdfInEnglish, isFalse);
  });

  test('hi: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(Catalog.label(c, lang: AppLang.hi),
            isNot(Catalog.label(c, lang: AppLang.en)),
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.hi).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
    expect(GuideContent.topics(lang: AppLang.hi).first.title, 'डैशबोर्ड');
  });

  test('Hindi months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.hi)[9], 'अक्टूबर');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.hi),
        '1 रमज़ान 1447 हि.');
    expect(Catalog.label('الطعام', lang: AppLang.hi), 'राशन');
    expect(CurrencyDefaults.suggest(AppLang.hi), 'INR');
  });

  test('the app texts use Latin digits', () async {
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('hi'));
    expect(l.valPasswordShort, contains('6'));
  });

  test('quick entry: everyday words, «कल», nukta or not, Devanagari digits',
      () {
    final DateTime today = DateTime(2026, 10, 25);
    final List<QuickEntry> all = QuickEntryParser.parseAll(
        'चाय 20; ऑटो 80 कल; वेतन 45000; दवा 300 परसों; '
        'बिजली का बिल 900; कपड़े 1200; सब्जी ५०',
        today: today);
    expect(all.map((QuickEntry e) => e.category).toList(), <String>[
      'المطاعم',
      'النقل',
      'راتب أساسي',
      'الصحة',
      'الفواتير',
      'الملابس',
      'الطعام',
    ]);
    expect(all[1].date, DateTime(2026, 10, 24));
    expect(all[2].type, TransactionType.income);
    expect(all[3].date, DateTime(2026, 10, 23));
    expect(all.last.amount, 50);
  });
}
