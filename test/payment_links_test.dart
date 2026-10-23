import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/payment_links.dart';

void main() {
  test('opens the payment providers and our own site over https', () {
    for (final String url in <String>[
      'https://smartbudget.dgotix.com/#/plans',
      'https://whop.com/checkout/plan_1?session=ch_1',
      'https://sandbox.whop.com/checkout/plan_1',
      'https://whop.com/@me/settings/memberships/',
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
      'https://whop.com@evil.example/',
      'https://whop.com.evil.example/',
      'https://evilwhop.com/',
      'javascript:alert(1)',
      'https://example.com/?next=https://whop.com',
      'https://paddle.com/', // no longer a payment provider
    ]) {
      expect(PaymentLinks.trusted(url), isNull, reason: '$url');
    }
  });
}
