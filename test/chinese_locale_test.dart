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
  test('zh is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('zh'));
    expect(AppLang.zh.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.zh)));
    expect(AppLang.zh.pdfInEnglish, isTrue);
  });

  test('zh: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(Catalog.label(c, lang: AppLang.zh),
            isNot(Catalog.label(c, lang: AppLang.en)),
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.zh).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
    expect(GuideContent.topics(lang: AppLang.zh).first.title, '总览');
  });

  test('Chinese months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.zh)[9], '十月');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.zh),
        '伊斯兰历1447年赖买丹月1日');
    expect(Catalog.label('الطعام', lang: AppLang.zh), '日用食品');
    expect(CurrencyDefaults.suggest(AppLang.zh), 'CNY');
  });

  test('the app texts use Latin digits', () async {
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('zh'));
    expect(l.valPasswordShort, contains('6'));
  });

  group('quick entry', () {
    final DateTime today = DateTime(2026, 10, 25);

    test('words run into the number, with or without spaces', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          '咖啡35元；昨天打车120，工资 25000；前天买药 80；电费900；'
          '超市买菜１５０',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الفواتير',
        'الطعام',
      ]);
      expect(all[0].amount, 35);
      expect(all[0].description, '咖啡');
      expect(all[1].date, DateTime(2026, 10, 24));
      expect(all[1].description, '打车');
      expect(all[2].type, TransactionType.income);
      expect(all[3].date, DateTime(2026, 10, 23));
      expect(all.last.amount, 150); // full-width digits
    });

    test('万 and 千', () {
      expect(QuickEntryParser.parse('房租3千', today: today)!.amount, 3000);
      expect(QuickEntryParser.parse('奖金1.5万', today: today)!.amount, 15000);
    });

    test('a named currency picks its wallet', () {
      final List<Wallet> wallets = <Wallet>[
        Wallet.general('CNY'),
        Wallet(
            id: 'w-usd',
            name: '美元储蓄',
            type: WalletType.savings,
            opening: const Money(0, 'USD'),
            createdAt: DateTime(2026)),
      ];
      final QuickEntry usd =
          QuickEntryParser.parse('订阅20美元', today: today, wallets: wallets)!;
      expect(usd.currency, 'USD');
      expect(usd.walletId, 'w-usd');
      expect(usd.description, '订阅');
      final QuickEntry cny =
          QuickEntryParser.parse('午饭30块钱', today: today, wallets: wallets)!;
      expect(cny.currency, 'CNY');
      expect(cny.category, 'المطاعم');
    });
  });
}
