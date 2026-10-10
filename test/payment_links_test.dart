import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/payment_links.dart';

void main() {
  test('opens the payment providers and our own site over https', () {
    for (final String url in <String>[
      'https://smartbudget.dgotix.com/?_ptxn=txn_01',
      'https://sandbox-customer-portal.paddle.com/cpl_1',
      'https://customer-portal.paddle.com/cpl_1',
      'https://pay.paddle.io/hsc_1',
      'https://www.paypal.com/webapps/billing/subscriptions?ba_token=1',
      'https://www.sandbox.paypal.com/myaccount/autopay',
    ]) {
      expect(PaymentLinks.trusted(url), isNotNull, reason: url);
    }
  });

  test('refuses anything else', () {
    for (final String? url in <String?>[
      null,
      '',
      'http://www.paypal.com/', // not https
      'https://paypal.com.evil.example/',
      'https://evilpaypal.com/',
      'https://paddle.com@evil.example/',
      'javascript:alert(1)',
      'https://example.com/?next=https://paddle.com',
    ]) {
      expect(PaymentLinks.trusted(url), isNull, reason: '$url');
    }
  });
}
