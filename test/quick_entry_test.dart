import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
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

    test('currency words are ignored', () {
      final QuickEntry e = p('بنزين 2000 دج');
      expect(e.amount, 2000);
      expect(e.description, 'بنزين');
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
}
