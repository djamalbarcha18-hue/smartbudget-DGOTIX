import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/billing/domain/coupon.dart';

void main() {
  test('server reasons map to what the user is told', () {
    expect(CouponResult.reasonFromId('rate_limited'), CouponReason.tooManyAttempts);
    expect(CouponResult.reasonFromId('already_used'), CouponReason.alreadyUsed);
    expect(CouponResult.reasonFromId('something_new'), CouponReason.invalid);
  });
}
