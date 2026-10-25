import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/money/currency_defaults.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/guide/domain/guide_content.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  test('ja is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('ja'));
    expect(AppLang.ja.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.ja)));
    expect(AppLang.ja.pdfInEnglish, isTrue);
  });

  test('ja: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(Catalog.label(c, lang: AppLang.ja),
            isNot(Catalog.label(c, lang: AppLang.en)),
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.ja).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
    expect(GuideContent.topics(lang: AppLang.ja).first.title, 'ダッシュボード');
  });

  test('Japanese months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.ja)[9], '10月');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.ja),
        'ヒジュラ暦1447年ラマダーン1日');
    expect(Catalog.label('الطعام', lang: AppLang.ja), '食料品');
    expect(CurrencyDefaults.suggest(AppLang.ja), 'JPY');
  });

  test('the app texts use Latin digits', () async {
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('ja'));
    expect(l.valPasswordShort, contains('6'));
  });

  group('quick entry', () {
    final DateTime today = DateTime(2026, 10, 25);

    test('words run into the number, with or without spaces', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'コーヒー500円、昨日タクシー1200、給料 250000、一昨日薬局 800、'
          '電気代9000、スーパー３千、パンツ 3000',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الفواتير',
        'الطعام',
        'الملابس', // «パンツ», not «パン»
      ]);
      expect(all[0].amount, 500);
      expect(all[0].description, 'コーヒー');
      expect(all[1].date, DateTime(2026, 10, 24));
      expect(all[2].type, TransactionType.income);
      expect(all[3].date, DateTime(2026, 10, 23));
      expect(all[5].amount, 3000); // full-width digit and 千
    });

    test('a named currency picks its wallet', () {
      final List<Wallet> wallets = <Wallet>[
        Wallet.general('JPY'),
        Wallet(
            id: 'w-usd',
            name: 'ドル貯金',
            type: WalletType.savings,
            opening: const Money(0, 'USD'),
            createdAt: DateTime(2026)),
      ];
      final QuickEntry usd =
          QuickEntryParser.parse('サブスク10ドル', today: today, wallets: wallets)!;
      expect(usd.currency, 'USD');
      expect(usd.category, 'الاشتراكات');
      final QuickEntry jpy =
          QuickEntryParser.parse('ランチ1000円', today: today, wallets: wallets)!;
      expect(jpy.currency, 'JPY');
      expect(jpy.description, 'ランチ');
    });
  });
}
