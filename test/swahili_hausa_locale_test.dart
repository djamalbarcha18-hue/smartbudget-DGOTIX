import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
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
  for (final (AppLang lang, String code) in <(AppLang, String)>[
    (AppLang.sw, 'sw'),
    (AppLang.ha, 'ha'),
  ]) {
    test('$code is translated but hidden for now', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
          contains(code));
      expect(lang.hidden, isTrue);
      expect(AppLang.offered, isNot(contains(lang)));
    });

    test('$code: categories, legal pages and guide are its own', () {
      for (final TransactionType t in TransactionType.values) {
        for (final String c in Catalog.categoriesFor(t)) {
          expect(_arabicLetters.hasMatch(Catalog.label(c, lang: lang)), isFalse,
              reason: c);
        }
      }
      for (final LegalDoc doc in LegalDoc.values) {
        expect(LegalContent.sections(doc, lang: lang).first.heading,
            isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
      }
      expect(GuideContent.topics(lang: lang).first.title,
          isNot(GuideContent.topics(lang: AppLang.en).first.title));
    });
  }

  test('Swahili months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.sw)[9], 'Oktoba');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.sw),
        '1 Ramadhani 1447 H');
    expect(Catalog.label('السكن', lang: AppLang.sw), 'Makazi');
    expect(CurrencyDefaults.suggest(AppLang.sw), 'KES');
  });

  test('Hausa months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.ha)[9], 'Oktoba');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.ha),
        '1 Ramadan 1447 H');
    expect(Catalog.label('الوقود', lang: AppLang.ha), 'Man fetur');
    expect(CurrencyDefaults.suggest(AppLang.ha), 'NGN');
  });

  group('quick entry', () {
    final DateTime today = DateTime(2026, 10, 25);

    test('Swahili: everyday words and "jana"', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'chai 50; nauli 100 jana; mshahara 42000; dawa 300; umeme 1000',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الفواتير',
      ]);
      expect(all[1].date, DateTime(2026, 10, 24));
      expect(all[2].type, TransactionType.income);
    });

    test('Hausa: everyday words, "jiya" and hooked letters typed either way',
        () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'shayi 200; achaba 500 jiya; albashi 150000; magani 900; '
          'kuɗin wuta 3000; kudin wuta 3000',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الفواتير',
        'الفواتير',
      ]);
      expect(all[1].date, DateTime(2026, 10, 24));
    });
  });

  testWidgets('Hausa opens: Flutter\'s own strings fall back to English',
      (WidgetTester t) async {
    late String backTooltip;
    await t.pumpWidget(MaterialApp(
      locale: const Locale('ha'),
      supportedLocales: const <Locale>[Locale('en'), Locale('ha')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      home: Builder(builder: (BuildContext context) {
        backTooltip = MaterialLocalizations.of(context).backButtonTooltip;
        return Text(AppLocalizations.of(context).authSignIn);
      }),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(backTooltip, 'Back');
    expect(find.text('Shiga'), findsOneWidget);
  });
}
