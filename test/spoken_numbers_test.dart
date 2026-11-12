import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/quick_entry/domain/spoken_numbers.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Amounts a speech engine writes as words become digits, so voice entry
/// records «قهوة مئتين» as 200.
void main() {
  String d(String s) => SpokenNumbers.toDigits(s);

  group('Arabic, standard and spoken', () {
    final Map<String, String> cases = <String, String>{
      'قهوة مئتين': 'قهوة 200',
      'كراء ألف': 'كراء 1000',
      'راتب خمسين ألف': 'راتب 50000',
      'حليب مية وعشرين': 'حليب 120',
      'ألفين وخمسمية': '2500',
      'ثلاث آلاف': '3000',
      'ميتين ألف': '200000',
      'ألف ونص': '1500',
      'مليون ونص': '1500000',
      'خمسة عشر': '15',
      'تلطاش': '13',
      'ثلاث مية': '300',
      'مئة و خمسة و عشرون': '125',
      'خبز بخمسين': 'خبز 50',
      'خبز خمسين.': 'خبز 50',
      'مائتان وخمسون': '250',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('French', () {
    final Map<String, String> cases = <String, String>{
      'courses deux mille cinq cents': 'courses 2500',
      'quatre-vingt-dix': '90',
      'quatre-vingt-dix-sept': '97',
      'soixante-quinze': '75',
      'soixante et onze': '71',
      'vingt et un': '21',
      'mille deux cents': '1200',
      'deux cent quatre-vingts': '280',
      'une baguette deux euros': 'une baguette 2 euros',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('English', () {
    final Map<String, String> cases = <String, String>{
      'coffee two hundred': 'coffee 200',
      'rent one thousand five hundred': 'rent 1500',
      'a hundred': '100',
      'twenty-five': '25',
      'one hundred and twenty': '120',
      'salary three thousand two hundred fifty': 'salary 3250',
      // The price, not the count.
      'two coffees ten dollars': 'two coffees 10 dollars',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('typed text is left alone', () {
    test('a digit already there', () {
      expect(d('قهوة واحدة 200'), 'قهوة واحدة 200');
      expect(d('coffee 2 x 150'), 'coffee 2 x 150');
    });
    test('a lone «one» is not an amount', () {
      expect(d('قهوة واحدة'), 'قهوة واحدة');
      expect(d('one coffee'), 'one coffee');
    });
    test('no number word at all', () {
      expect(d('قهوة مع صديق'), 'قهوة مع صديق');
      expect(d(''), '');
    });
  });

  group('the parser records the amount in digits', () {
    final DateTime today = DateTime(2026, 11, 13);
    QuickEntry p(String s) => QuickEntryParser.parse(s, today: today)!;

    test('Arabic', () {
      expect(p('قهوة مئتين').amount, 200);
      expect(p('كراء ألف').amount, 1000);
      expect(p('خبز خمسين').amount, 50);
    });
    test('income said in words', () {
      final QuickEntry e = p('راتب خمسين ألف');
      expect(e.amount, 50000);
      expect(e.type, TransactionType.income);
    });
    test('French and English', () {
      expect(p('courses deux mille cinq cents').amount, 2500);
      expect(p('coffee two hundred').amount, 200);
    });
    test('several entries said at once', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'خبز خمسين، حليب مية وعشرين',
          today: today);
      expect(all.map((QuickEntry e) => e.amount), <double>[50, 120]);
    });
    test('digits still win', () {
      expect(p('قهوة واحدة 200').amount, 200);
    });
  });
}
