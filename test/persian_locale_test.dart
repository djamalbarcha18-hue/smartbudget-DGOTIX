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
  test('fa is translated, right to left, and hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('fa'));
    expect(AppLang.fa.hidden, isTrue);
    expect(AppLang.fa.rtl, isTrue);
    // Persian letters (گ چ ژ ی ک) need Noto Naskh, like Urdu.
    expect(AppLang.fa.naskh, isTrue);
    expect(AppLang.ar.naskh, isFalse);
    expect(AppLang.offered, isNot(contains(AppLang.fa)));
  });

  test('fa: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(Catalog.label(c, lang: AppLang.fa),
            isNot(Catalog.label(c, lang: AppLang.ar)),
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.fa).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
    expect(GuideContent.topics(lang: AppLang.fa).length,
        GuideContent.topics(lang: AppLang.en).length);
    expect(GuideContent.topics(lang: AppLang.fa).first.title, 'داشبورد');
  });

  test('Persian months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.fa)[9], 'اکتبر');
    expect(
        const HijriDate(1447, 9, 1).format(lang: AppLang.fa), '1 رمضان 1447 ق');
    expect(Catalog.label('الطعام', lang: AppLang.fa), 'خواربار');
    expect(CurrencyDefaults.suggest(AppLang.fa), 'IRR');
  });

  test('the app texts use Latin digits', () async {
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('fa'));
    expect(l.valPasswordShort, contains('6'));
    expect(l.riskSpendingExceedsIncome, contains('100%'));
  });

  test('quick entry: everyday words, «دیروز», with or without ‌', () {
    final DateTime today = DateTime(2026, 10, 25);
    final List<QuickEntry> all = QuickEntryParser.parseAll(
        'قهوه 35; تاکسی 120 دیروز; حقوق 25000; داروخانه 180 پریروز; '
        'قبض برق 500; لباس 400 نقدی; نان 20',
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
  });
}
