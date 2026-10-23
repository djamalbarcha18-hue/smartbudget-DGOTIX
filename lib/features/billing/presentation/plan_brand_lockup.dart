import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/brand/dgotix_brand_lockup.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// The brand lockup with the signed-in user's plan as its badge: FREE, or
/// PRO standing out.
class PlanBrandLockup extends ConsumerWidget {
  const PlanBrandLockup({super.key, this.logoHeight = 40});

  final double logoHeight;

  static LockupBadgeStyle styleFor(Plan plan) => switch (plan) {
        Plan.free => LockupBadgeStyle.subtle,
        Plan.pro => LockupBadgeStyle.solid,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Plan plan = ref.watch(effectivePlanProvider);
    return DgotixBrandLockup(
      logoHeight: logoHeight,
      badge: plan.label,
      badgeStyle: styleFor(plan),
    );
  }
}
