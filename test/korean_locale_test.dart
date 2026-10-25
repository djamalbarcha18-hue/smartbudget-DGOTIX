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
  test('ko is translated but hidden for now', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('ko'));
    expect(AppLang.ko.hidden, isTrue);
    expect(AppLang.offered, isNot(contains(AppLang.ko)));
    expect(AppLang.ko.pdfInEnglish, isTrue);
  });

  test('ko: categories, legal pages and guide are its own', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(Catalog.label(c, lang: AppLang.ko),
            isNot(Catalog.label(c, lang: AppLang.en)),
            reason: c);
      }
    }
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.ko).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
    expect(GuideContent.topics(lang: AppLang.ko).first.title, '대시보드');
  });

  test('Korean months, Hijri date and currency', () {
    expect(MonthNames.full(lang: AppLang.ko)[9], '10월');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.ko),
        '히즈라력 1447년 라마단 1일');
    expect(Catalog.label('الطعام', lang: AppLang.ko), '장보기');
    expect(CurrencyDefaults.suggest(AppLang.ko), 'KRW');
  });

  test('the app texts use Latin digits', () async {
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('ko'));
    expect(l.valPasswordShort, contains('6'));
  });

  group('quick entry', () {
    final DateTime today = DateTime(2026, 10, 25);

    test('particles, 만 and 원', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          '커피 4500원; 어제 택시비 12000; 월급 3000000; 그저께 약국 8000; '
          '전기요금 5만원; 마트에서 장보기 3만',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
        'الفواتير',
        'الطعام',
      ]);
      expect(all[0].description, '커피');
      expect(all[0].currency, 'KRW');
      expect(all[1].date, DateTime(2026, 10, 24));
      expect(all[2].type, TransactionType.income);
      expect(all[3].date, DateTime(2026, 10, 23));
      expect(all[4].amount, 50000);
      expect(all[5].amount, 30000);
    });

    test('a one-letter currency only right after the amount', () {
      final QuickEntry room =
          QuickEntryParser.parse('원룸 월세 50만', today: today)!;
      expect(room.currency, isNull);
      expect(room.category, 'السكن');
      expect(room.description, '원룸 월세');
      expect(QuickEntryParser.parse('원피스 39000', today: today)!.category,
          'الملابس');
      final QuickEntry cny = QuickEntryParser.parse('35元咖啡', today: today)!;
      expect(cny.currency, 'CNY');
      expect(cny.description, '咖啡');
      expect(cny.category, 'المطاعم');
      // «服» alone is clothing, but not inside «服务费» (service fee).
      expect(QuickEntryParser.parse('服务费 30', today: today)!.category,
          isNot('الملابس'));
    });

    test('a named currency picks its wallet', () {
      final List<Wallet> wallets = <Wallet>[
        Wallet.general('KRW'),
        Wallet(
            id: 'w-usd',
            name: '달러 저축',
            type: WalletType.savings,
            opening: const Money(0, 'USD'),
            createdAt: DateTime(2026)),
      ];
      final QuickEntry usd =
          QuickEntryParser.parse('구독 10달러', today: today, wallets: wallets)!;
      expect(usd.currency, 'USD');
      expect(usd.walletId, 'w-usd');
      expect(usd.category, 'الاشتراكات');
    });
  });
}
