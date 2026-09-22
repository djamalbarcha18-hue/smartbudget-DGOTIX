import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/billing/domain/coupon.dart';

/// Validates a coupon code against the server (`coupon-validate` Edge Function).
///
/// Runs in probe mode (no plan) for a pre-checkout preview: it confirms the
/// code and reports its effect, without redeeming it (redemption happens at
/// checkout). Coupons are server-only, so this is the only way to test a code —
/// nothing about other codes is exposed. Any transport failure maps to a
/// network reason; it never throws to the UI.
class CouponService {
  const CouponService();

  Future<CouponResult> validate(String rawCode) async {
    final String code = rawCode.trim();
    if (code.isEmpty) return CouponResult.rejected(CouponReason.invalid);
    try {
      final FunctionResponse res = await Supabase.instance.client.functions
          .invoke('coupon-validate', body: <String, dynamic>{'code': code});
      final Object? data = res.data;
      if (data is! Map) return CouponResult.rejected(CouponReason.network);
      final Map<String, dynamic> map = data.cast<String, dynamic>();
      if (map['valid'] == true) {
        return CouponResult.ok(
          kind: CouponResult.kindFromId(map['kind']),
          value: (map['value'] as num?)?.toDouble() ?? 0,
          targetPlan: map['targetPlan'] as String?,
          targetPeriod: map['targetPeriod'] as String?,
          trialDays: (map['trialDays'] as num?)?.toInt(),
        );
      }
      return CouponResult.rejected(CouponResult.reasonFromId(map['reason']));
    } on FunctionException catch (_) {
      return CouponResult.rejected(CouponReason.network);
    } catch (_) {
      return CouponResult.rejected(CouponReason.network);
    }
  }
}

final couponServiceProvider =
    Provider<CouponService>((_) => const CouponService());
