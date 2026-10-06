import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/domain/user_subscription.dart';

UserSubscription sub(String plan, String status) => UserSubscription.fromRow(
    <String, dynamic>{'plan': plan, 'status': status, 'provider': 'paddle'})!;

void main() {
  test('an active or trialing paid plan is in force', () {
    expect(sub('pro', 'active').isPaidActive, isTrue);
    expect(sub('basic', 'trialing').isPaidActive, isTrue);
    expect(sub('pro', 'active').needsPaymentFix, isFalse);
  });

  test('a failed or paused payment asks to fix the payment method', () {
    for (final String s in <String>['past_due', 'paused']) {
      final UserSubscription x = sub('pro', s);
      expect(x.isPaidActive, isFalse, reason: s);
      expect(x.needsPaymentFix, isTrue, reason: s);
      expect(x.plan, Plan.pro);
    }
  });

  test('cancelled or refunded: neither', () {
    for (final String s in <String>['canceled', 'refunded']) {
      expect(sub('free', s).isPaidActive, isFalse, reason: s);
      expect(sub('free', s).needsPaymentFix, isFalse, reason: s);
    }
  });
}
