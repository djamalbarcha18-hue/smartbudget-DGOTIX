import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

void main() {
  final DateTime today = DateTime(2026, 9, 27, 15, 30);
  QuickEntry p(String s,
          {List<String> customExpense = const <String>[],
          List<String> customIncome = const <String>[]}) =>
      QuickEntryParser.parse(s,
          today: today,
          customExpense: customExpense,
          customIncome: customIncome)!;

  group('amounts', () {
    test('plain, Arabic-Indic digits and decimals', () {
      expect(p('قهوة 200').amount, 200);
      expect(p('قهوة ٢٠٠').amount, 200);
      expect(p('coffee 3.5').amount, 3.5);
      expect(p('café 12,5').amount, 12.5);
    });

    test('thousands separators and multipliers', () {
      expect(p('كراء 25,000').amount, 25000);
      expect(p('loyer 25.000').amount, 25000);
      expect(p('loyer 25 000').amount, 25000);
      expect(p('salaire 85k').amount, 85000);
      expect(p('كراء 3 آلاف').amount, 3000);
      expect(p('خبز 1,250.75').amount, 1250.75);
    });

    test('no amount → nothing', () {
      expect(QuickEntryParser.parse('قهوة', today: today), isNull);
      expect(QuickEntryParser.parse('   ', today: today), isNull);
    });

    test('currency words are taken out of the description', () {
      final QuickEntry e = p('بنزين 2000 دج');
      expect(e.amount, 2000);
      expect(e.description, 'بنزين');
      expect(e.currency, 'DZD');
      expect(p('قهوة 200').currency, isNull);
    });
  });

  group('categories', () {
    test('Arabic, darija, French and English keywords', () {
      expect(p('القهوة 200').category, 'المطاعم');
      expect(p('فليكسي 1000').category, 'الاتصالات والإنترنت');
      expect(p('الحوت 1500').category, 'الطعام');
      expect(p('essence 2000').category, 'الوقود');
      expect(p('pharmacie 850').category, 'الصحة');
      expect(p('taxi 300').category, 'النقل');
      expect(p('فاتورة سونلغاز 4200').category, 'الفواتير');
      expect(p('netflix 1200').category, 'الاشتراكات');
    });

    test('whole words only (no false matches inside other words)', () {
      expect(p('bonus 5000').category, 'مكافآت وحوافز');
      expect(p('volaille 900').category, 'أخرى');
    });

    test('longest keyword wins', () {
      expect(p('حليب اطفال 800').category, 'الأطفال والعائلة');
    });

    test('unknown words fall back to Other as an expense', () {
      final QuickEntry e = p('شيء غريب 100');
      expect(e.type, TransactionType.expense);
      expect(e.category, 'أخرى');
      expect(e.recognized, isFalse);
    });

    test('custom categories are matched first', () {
      final QuickEntry e = p('قطط 400', customExpense: <String>['قطط']);
      expect(e.category, 'قطط');
      expect(e.recognized, isTrue);
    });
  });

  group('income', () {
    test('income keywords', () {
      final QuickEntry e = p('الشهرية 85000');
      expect(e.type, TransactionType.income);
      expect(e.category, 'راتب أساسي');
      expect(p('salaire 60000').type, TransactionType.income);
    });

    test('a leading + or an income word makes it income', () {
      expect(p('+ 5000').type, TransactionType.income);
      expect(p('استلمت 3000').type, TransactionType.income);
      final QuickEntry mismatch = p('+ قهوة 200');
      expect(mismatch.type, TransactionType.income);
      expect(mismatch.category, 'أخرى');
    });
  });

  group('dates', () {
    test('today by default, yesterday and the day before', () {
      expect(p('قهوة 200').date, DateTime(2026, 9, 27));
      final QuickEntry y = p('خبز 50 أمس');
      expect(y.date, DateTime(2026, 9, 26));
      expect(y.description, 'خبز');
      expect(p('taxi 300 hier').date, DateTime(2026, 9, 26));
      expect(p('قهوة 200 أول أمس').date, DateTime(2026, 9, 25));
    });
  });

  test('several entries at once', () {
    final List<QuickEntry> all = QuickEntryParser.parseAll(
        'قهوة 200، خبز 50\nessence 2000؛ نص بلا رقم',
        today: today);
    expect(all.map((QuickEntry e) => e.amount), <double>[200, 50, 2000]);
    expect(all.map((QuickEntry e) => e.category),
        <String>['المطاعم', 'الطعام', 'الوقود']);
  });

  group('wallets', () {
    final List<Wallet> wallets = <Wallet>[
      Wallet.general('DZD'),
      Wallet(id: 'w-cash', name: 'الجيب', type: WalletType.cash,
          opening: const Money(0, 'DZD'), createdAt: DateTime(2026)),
      Wallet(id: 'w-ccp', name: 'CCP', type: WalletType.bank,
          opening: const Money(0, 'DZD'), createdAt: DateTime(2026)),
      Wallet(id: 'w-sal', name: 'حساب الراتب', type: WalletType.bank,
          opening: const Money(0, 'DZD'), createdAt: DateTime(2026)),
    ];
    QuickEntry q(String s) =>
        QuickEntryParser.parse(s, today: today, wallets: wallets)!;

    test('a wallet named in the text is picked and removed', () {
      final QuickEntry e = q('الشهرية 85000 CCP');
      expect(e.walletId, 'w-ccp');
      expect(e.type, TransactionType.income);
      expect(e.description, 'الشهرية');
      expect(q('قهوة 200 من حساب الراتب').walletId, 'w-sal');
    });

    test('generic cash words map to the cash wallet', () {
      final QuickEntry e = q('قهوة 200 نقدا');
      expect(e.walletId, 'w-cash');
      expect(e.category, 'المطاعم');
      expect(e.description, 'قهوة');
      expect(q('taxi 300 cash').walletId, 'w-cash');
    });

    test('no wallet mentioned → null (the default is used)', () {
      expect(q('قهوة 200').walletId, isNull);
    });
  });

  group('currencies', () {
    // Samer: riyal base, a riyal bank account (default), cash and a dollar
    // savings wallet.
    final List<Wallet> wallets = <Wallet>[
      Wallet.general('SAR'),
      Wallet(id: 'w-sar', name: 'الراجحي', type: WalletType.bank,
          opening: const Money(0, 'SAR'), createdAt: DateTime(2026)),
      Wallet(id: 'w-cash', name: 'كاش', type: WalletType.cash,
          opening: const Money(0, 'SAR'), createdAt: DateTime(2026)),
      Wallet(id: 'w-usd', name: 'ادخار', type: WalletType.savings,
          opening: const Money(0, 'USD'), createdAt: DateTime(2026)),
    ];
    QuickEntry q(String s) => QuickEntryParser.parse(s,
        today: today, wallets: wallets, defaultWalletId: 'w-sar')!;

    test('a dollar amount goes to the dollar wallet', () {
      for (final String s in <String>[
        'اشتراك 12 دولار',
        'اشتراك 12 بالدولار',
        'اشتراك \$12',
        'اشتراك 12\$',
        'subscription 12 usd',
        'subscription 12 dollars',
      ]) {
        final QuickEntry e = q(s);
        expect(e.currency, 'USD', reason: s);
        expect(e.walletId, 'w-usd', reason: s);
        expect(e.amount, 12, reason: s);
        expect(e.category, 'الاشتراكات', reason: s);
      }
      expect(q('اشتراك 12 دولار').description, 'اشتراك');
    });

    test('the default wallet keeps entries in its own currency', () {
      final QuickEntry e = q('قهوة 15 ريال');
      expect(e.currency, 'SAR');
      expect(e.walletId, isNull);
      expect(q('قهوة 15 ر.س').currency, 'SAR');
      expect(q('قهوة 15 ر.س').description, 'قهوة');
    });

    test('a shared word is settled by the wallets held', () {
      // «ريال» is the Saudi riyal here; «ريال قطري» stays Qatari.
      expect(q('غداء 40 ريالات').currency, 'SAR');
      expect(q('غداء 40 ريال قطري').currency, 'QAR');
      // With only dinar wallets, «دينار» is the dinar they hold.
      final QuickEntry kw = QuickEntryParser.parse('غداء 3 دينار',
          today: today,
          wallets: <Wallet>[Wallet.general('KWD')],
          defaultWalletId: Wallet.generalId)!;
      expect(kw.currency, 'KWD');
    });

    test('a named wallet wins; a currency no wallet holds is reported', () {
      // Cash is in riyals: the entry is flagged by the sheet, not moved.
      final QuickEntry cash = q('قهوة 5 دولار كاش');
      expect(cash.walletId, 'w-cash');
      expect(cash.currency, 'USD');
      // No euro wallet: no wallet is picked for it.
      final QuickEntry eur = q('كتاب 20 يورو');
      expect(eur.currency, 'EUR');
      expect(eur.walletId, isNull);
    });

    test('every supported currency, by name, code and symbol', () {
      String? cur(String s, String held) => QuickEntryParser.parse(s,
              today: today,
              wallets: <Wallet>[Wallet.general(held)],
              defaultWalletId: Wallet.generalId)!
          .currency;
      for (final Currency c in <Currency>[Currencies.usd, ...Currencies.all]) {
        expect(cur('هدية 50 ${c.nameAr}', c.code), c.code, reason: c.nameAr);
        expect(cur('gift 50 ${c.nameEn}', c.code), c.code, reason: c.nameEn);
        expect(cur('gift 50 ${c.code}', c.code), c.code, reason: c.code);
        if (c.symbol.length > 1 || !RegExp(r'^\p{L}$', unicode: true)
            .hasMatch(c.symbol)) {
          expect(cur('gift 50 ${c.symbol}', c.code), c.code, reason: c.symbol);
        }
      }
    });

    test('Arabic forms with and without the article', () {
      expect(q('غداء 40 الريال السعودي').currency, 'SAR');
      expect(q('غداء 40 الريال السعودي').description, 'غداء');
      expect(q('عطر 100 درهم إماراتي').currency, 'AED');
      expect(q('هدية 20 ليرة تركية').currency, 'TRY');
      expect(q('هدية 20 ليرات').currency, 'LBP');
      expect(q('سفر 5000 ين ياباني').currency, 'JPY');
      expect(q('كتاب 30 دولار كندي').currency, 'CAD');
      expect(q('book 30 C\$').currency, 'CAD');
      expect(q('book 30 \$').currency, 'USD');
      expect(q('hotel 30 euros').currency, 'EUR');
    });

    test('everyday words are not read as currencies', () {
      expect(q('تقسيم بين صديقين 200').currency, isNull);
      expect(q('try 50').currency, isNull);
      expect(q('real estate 50').currency, isNull);
      expect(q('won 50').currency, isNull);
      expect(q('قهوة 15').currency, isNull);
    });

    test('several entries at once', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'اشتراك 12 دولار، قهوة 15',
          today: today,
          wallets: wallets,
          defaultWalletId: 'w-sar');
      expect(all.map((QuickEntry e) => e.walletId), <String?>['w-usd', null]);
      expect(all.map((QuickEntry e) => e.currency), <String?>['USD', null]);
    });
  });
}
