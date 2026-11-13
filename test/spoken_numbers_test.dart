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

  group('other Arabic varieties', () {
    final Map<String, String> cases = <String, String>{
      // Egyptian
      'عيش خمستاشر': 'عيش 15',
      'إيجار تلات تلاف': 'إيجار 3000',
      'ميت جنيه': '100 جنيه',
      'ألف وربع': '1250',
      'تلتمية وخمسين': '350',
      // Levantine
      'خبز تنين وعشرين': 'خبز 22',
      'قهوة خمسطعش': 'قهوة 15',
      'أجار ألف وتلتمية': 'أجار 1300',
      // Gulf and Iraqi
      'بنزين ثنعش': 'بنزين 12',
      'غداء ثمنطعش': 'غداء 18',
      'إيجار ثلاثة آلاف وخمسمية': 'إيجار 3500',
      // Moroccan
      'حليب جوج': 'حليب 2',
      'كراء جوج آلاف': 'كراء 2000',
      'مية وربع': '125',
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

  group('Hindi', () {
    final Map<String, String> cases = <String, String>{
      'चाय पचास': 'चाय 50',
      'किराया पाँच हज़ार': 'किराया 5000',
      'किराया पांच हजार': 'किराया 5000',
      'सब्ज़ी डेढ़ सौ': 'सब्ज़ी 150',
      'ढाई हज़ार': '2500',
      'साढ़े तीन सौ': '350',
      'सवा लाख': '125000',
      'पौने दो सौ': '175',
      'तनख्वाह पच्चीस हज़ार': 'तनख्वाह 25000',
      'दो लाख पचास हज़ार': '250000',
      'एक सौ बीस': '120',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('Urdu', () {
    final Map<String, String> cases = <String, String>{
      'چائے پچاس': 'چائے 50',
      'کرایہ پانچ ہزار': 'کرایہ 5000',
      'ڈیڑھ سو': '150',
      'ڈھائی ہزار': '2500',
      'ساڑھے تین سو': '350',
      'تنخواہ پچیس ہزار': 'تنخواہ 25000',
      'دو لاکھ': '200000',
      'سوا لاکھ': '125000',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('Persian', () {
    final Map<String, String> cases = <String, String>{
      'قهوه پنجاه هزار': 'قهوه 50000',
      'اجاره دو میلیون': 'اجاره 2000000',
      'سیصد و پنجاه': '350',
      'بیست و پنج هزار': '25000',
      'صد هزار': '100000',
      'نه': 'نه',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('Turkish', () {
    final Map<String, String> cases = <String, String>{
      'kahve elli': 'kahve 50',
      'kira iki bin beş yüz': 'kira 2500',
      'maaş otuz bin': 'maaş 30000',
      'on beş': '15',
      'yüz yirmi': '120',
      'kahve on': 'kahve on',
      'bin': 'bin',
    };
    cases.forEach((String said, String written) {
      test('«$said» → «$written»', () => expect(d(said), written));
    });
  });

  group('Indonesian and Malay', () {
    final Map<String, String> cases = <String, String>{
      'kopi dua puluh lima ribu': 'kopi 25000',
      'sewa satu juta': 'sewa 1000000',
      'makan seratus lima puluh ribu': 'makan 150000',
      'dua belas ribu': '12000',
      'seribu': '1000',
      'tiga ratus dua puluh': '320',
      'gaji lima juta': 'gaji 5000000',
      'lapan ribu': '8000',
      'Ahmad bin Ali': 'Ahmad bin Ali',
      'sebelas': '11',
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
    test('Hindi, Urdu, Persian, Turkish, Indonesian', () {
      expect(p('किराया पांच हजार').amount, 5000);
      expect(p('ڈھائی ہزار').amount, 2500);
      expect(p('اجاره دو میلیون').amount, 2000000);
      expect(p('kira iki bin beş yüz').amount, 2500);
      expect(p('kopi dua puluh lima ribu').amount, 25000);
    });
    test('digits still win', () {
      expect(p('قهوة واحدة 200').amount, 200);
    });
  });
}
