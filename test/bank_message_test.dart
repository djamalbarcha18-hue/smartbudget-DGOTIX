import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/quick_entry/domain/bank_message.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 25, 14);
  BankMessage? p(String s) => BankMessageParser.parse(s, today: today);

  test('an English card payment, not the balance', () {
    final BankMessage m = p('Purchase of SAR 120.50 at CARREFOUR on '
        '25/10/2026. Available balance: SAR 3,450.00')!;
    expect(m.amount, 120.5);
    expect(m.currency, 'SAR');
    expect(m.income, isFalse);
    expect(m.merchant, 'CARREFOUR');
    expect(m.date, DateTime(2026, 10, 25));
  });

  test('an Arabic payment: masked card, merchant and date', () {
    final BankMessage m = p('تم خصم 250.00 ر.س من بطاقتك ****1234 لدى '
        'صيدلية النهدي بتاريخ 24/10/2026. الرصيد المتاح 1,200.00 ر.س')!;
    expect(m.amount, 250);
    expect(m.currency, 'SAR');
    expect(m.income, isFalse);
    expect(m.merchant, 'صيدلية النهدي');
    expect(m.date, DateTime(2026, 10, 24));
  });

  test('a salary credited, with lakh grouping in the balance', () {
    final BankMessage m = p('Your a/c XX4521 is credited with INR 25,000.00 '
        'on 20-Oct-26 by NEFT from ACME LTD. Avl Bal INR 1,02,345.67')!;
    expect(m.amount, 25000);
    expect(m.currency, 'INR');
    expect(m.income, isTrue);
    expect(m.merchant, 'ACME LTD');
    expect(m.date, DateTime(2026, 10, 20));
  });

  test('French: comma decimals and spaces between thousands', () {
    final BankMessage m = p('Paiement CB de 45,90 EUR chez MONOPRIX le '
        '23/10/2026. Solde : 1 234,56 EUR')!;
    expect(m.amount, 45.9);
    expect(m.currency, 'EUR');
    expect(m.merchant, 'MONOPRIX');
    expect(m.date, DateTime(2026, 10, 23));

    final BankMessage w = p('Retrait de 10 000,00 DA le 22/10/2026')!;
    expect(w.amount, 10000);
    expect(w.currency, 'DZD');
    expect(w.income, isFalse);
  });

  test('Arabic digits and a deposit', () {
    final BankMessage m = p('تم إيداع ٥٠٠٠ د.ج في حسابك')!;
    expect(m.amount, 5000);
    expect(m.currency, 'DZD');
    expect(m.income, isTrue);
  });

  test('an amount after "amount", and a lone number in a payment', () {
    expect(p('Debit card payment. Amount: 89.99. Ref 99812')!.amount, 89.99);
    expect(p('Payment received 300')!.amount, 300);
  });

  test('one-time codes and messages without an amount are ignored', () {
    expect(p('Your OTP is 482913. Do not share it.'), isNull);
    expect(p('رمز التحقق الخاص بك هو 4821'), isNull);
    expect(p('Welcome to your new bank app!'), isNull);
    expect(p(''), isNull);
  });

  test('no date or a future date: none', () {
    expect(p('Purchase of USD 12.00 at CAFE')!.date, isNull);
    expect(p('Purchase of USD 12.00 at CAFE on 30/12/2026')!.date, isNull);
  });

  test('"Rs." is not the end of a sentence', () {
    final BankMessage m = p('Rs. 1,499 spent on your card at AMAZON')!;
    expect(m.amount, 1499);
    expect(m.merchant, 'AMAZON');
  });

  test('a pasted bank message is told apart from a quick-entry line', () {
    for (final String s in <String>[
      'Purchase of SAR 120.50 at CARREFOUR on 25/10/2026. '
          'Available balance: SAR 3,450.00',
      'تم خصم 250.00 ر.س من بطاقتك ****1234 لدى صيدلية النهدي بتاريخ 24/10/2026',
      'Your a/c XX4521 is credited with INR 25,000.00 on 20-Oct-26',
    ]) {
      expect(BankMessageParser.looksLikeMessage(s), isTrue, reason: s);
    }
    for (final String s in <String>[
      'قهوة 35',
      'taxi 12 yesterday; salary 4200',
      'شراء ملابس للأطفال من السوق الكبير 3000',
      'Your OTP is 482913 for the payment of USD 20.00 at SHOP',
    ]) {
      expect(BankMessageParser.looksLikeMessage(s), isFalse, reason: s);
    }
  });

  test('a message pasted into one line, its line breaks gone', () {
    final BankMessage m = p('Purchase of SAR 120.50 at CARREFOUR on '
        '25/10/2026.Available balance: SAR 3,450.00')!;
    expect(m.amount, 120.5);
    expect(m.merchant, 'CARREFOUR');
  });

  group('messages in every language of the app', () {
    // (message, amount, currency, income)
    final List<(String, double, String?, bool)> cases =
        <(String, double, String?, bool)>[
      ('Purchase of KD 12.500 at SULTAN CENTER', 12.5, 'KWD', false),
      ('Betaling van EUR 23,50 bij ALBERT HEIJN op 24-10-2026. Saldo: '
          'EUR 1.204,10', 23.5, 'EUR', false),
      ('Salaris ontvangen: EUR 2.450,00 van ACME BV', 2450, 'EUR', true),
      ('Aankoop by WOOLWORTHS R349.99 op 24/10/2026. Saldo R5 120.00',
          349.99, 'ZAR', false),
      ('Kupovina 45,90 KM kod KONZUM 24.10.2026. Raspoloživo stanje: '
          '1.230,00 KM', 45.9, 'BAM', false),
      ('Uplata na vaš račun 1.500,00 KM', 1500, 'BAM', true),
      ('Pagesë me kartë 2.500 ALL në SPAR më 24/10/2026. Gjendja: 40.000 ALL',
          2500, 'ALL', false),
      ('Umepokea Ksh1,000.00 kutoka JOHN DOE tarehe 24/10/26. Salio jipya '
          'ni Ksh5,430.00', 1000, 'KES', true),
      ('Umelipa Ksh250.00 kwa DUKA LA MAMA. Salio Ksh3,000.00', 250, 'KES',
          false),
      ('An cire ₦5,000.00 daga asusunka. Ragowar kuɗi: ₦20,000.00', 5000,
          'NGN', false),
      ('आपके खाते XX1234 से रु. 500.00 डेबिट किए गए। उपलब्ध शेष रु 3,450.00',
          500, null, false),
      ('आपके खाते में ₹२५,००० जमा किए गए', 25000, 'INR', true),
      ('آپ کے اکاؤنٹ سے Rs. 2,500 کی خریداری کی گئی۔ دستیاب بیلنس Rs. 10,000',
          2500, null, false),
      ('برداشت: ۵۰۰,۰۰۰ ریال\nمانده: ۱,۲۰۰,۰۰۰ ریال', 500000, 'IRR', false),
      ('واریز: 3,000,000 ریال', 3000000, 'IRR', true),
      ('【招商银行】您账户1234于10月24日15:20消费人民币120.50元，可用余额3450.00元。',
          120.5, 'CNY', false),
      ('您尾号1234的卡10月24日工资收入8,000.00元，余额12,000.00元', 8000, null,
          true),
      ('【三井住友カード】ご利用日時:10/24 12:30 ご利用先:セブン-イレブン ご利用金額:1,200円',
          1200, 'JPY', false),
      ('10月25日 給与 入金 250,000円 残高 512,000円', 250000, 'JPY', true),
      ('[Web발신]\n신한카드(1234)승인 홍*동 12,000원(일시불)10/24 12:30 스타벅스 '
          '누적1,234,560원', 12000, 'KRW', false),
      ('신한카드 승인취소 12,000원 10/24', 12000, 'KRW', true),
    ];
    for (final (String text, double amount, String? cur, bool income)
        in cases) {
      test(text, () {
        final BankMessage m = p(text)!;
        expect(m.amount, amount);
        expect(m.currency, cur);
        expect(m.income, income);
      });
    }

    test('merchants and dates where the message gives them', () {
      expect(p('Betaling van EUR 23,50 bij ALBERT HEIJN op 24-10-2026')!
          .merchant, 'ALBERT HEIJN');
      expect(p('Umelipa Ksh250.00 kwa DUKA LA MAMA. Salio Ksh3,000.00')!
          .merchant, 'DUKA LA MAMA');
      expect(
          p('ご利用日時:10/24 12:30 ご利用先:セブン-イレブン ご利用金額:1,200円')!.merchant,
          'セブン-イレブン');
      expect(p('【招商银行】您账户1234于10月24日15:20消费人民币120.50元')!.date,
          DateTime(2026, 10, 24));
      expect(p('2026년 10월 24일 출금 50,000원')!.date, DateTime(2026, 10, 24));
    });

    test('one-time codes in other languages', () {
      for (final String s in <String>[
        '您的验证码是482913，5分钟内有效',
        '[Web발신] 인증번호 [482913]를 입력해주세요',
        'आपका ओटीपी 482913 है',
        'کد تایید شما: 482913',
      ]) {
        expect(p(s), isNull, reason: s);
      }
    });

    test('a Chinese message is told apart from a quick-entry line', () {
      expect(
          BankMessageParser.looksLikeMessage(
              '您账户1234于10月24日消费人民币120.50元，可用余额3450.00元'),
          isTrue);
      expect(BankMessageParser.looksLikeMessage('咖啡 35元'), isFalse);
    });
  });
}
