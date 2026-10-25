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

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

void main() {
  test('af is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('af'));
    expect(AppLang.af.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.af)));
  });

  test('af: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.af)),
            isFalse,
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.af).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
      expect(LegalContent.sections(doc, lang: AppLang.af).first.heading,
          isNot(LegalContent.sections(doc, lang: AppLang.en).first.heading));
    }
    expect(GuideContent.topics(lang: AppLang.af).length,
        GuideContent.topics(lang: AppLang.en).length);
    expect(GuideContent.topics(lang: AppLang.af).first.title, 'Oorsig');
  });

  test('Afrikaans months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.af)[9], 'Oktober');
    expect(MonthNames.short(lang: AppLang.af)[11], 'Des');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.af),
        '1 Ramadan 1447 H.');
    expect(Catalog.label('الطعام', lang: AppLang.af), 'Kruideniersware');
    expect(CurrencyDefaults.suggest(AppLang.af), 'ZAR');
  });

  test('quick entry: everyday words, "gister" and "eergister"', () {
    final DateTime today = DateTime(2026, 10, 25);
    final List<QuickEntry> all = QuickEntryParser.parseAll(
        'koffie 35; taxi 120 gister; salaris 25000; apteek 180 eergister; '
        'krag 500; klere 400 kontant',
        today: today);
    expect(all.map((QuickEntry e) => e.category).toList(), <String>[
      'المطاعم',
      'النقل',
      'راتب أساسي',
      'الصحة',
      'الفواتير',
      'الملابس',
    ]);
    expect(all[1].date, DateTime(2026, 10, 24));
    expect(all[2].type, TransactionType.income);
    expect(all[3].date, DateTime(2026, 10, 23));
  });

  testWidgets('Afrikaans opens with Flutter\'s own Afrikaans strings',
      (WidgetTester t) async {
    late String backTooltip;
    await t.pumpWidget(MaterialApp(
      locale: const Locale('af'),
      supportedLocales: const <Locale>[Locale('en'), Locale('af')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(builder: (BuildContext context) {
        backTooltip = MaterialLocalizations.of(context).backButtonTooltip;
        return Text(AppLocalizations.of(context).authSignIn);
      }),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(backTooltip, 'Terug');
    expect(find.text('Meld aan'), findsOneWidget);
  });
}
