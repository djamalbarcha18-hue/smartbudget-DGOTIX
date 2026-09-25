import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the beta build unlocks every paid feature', () {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    expect(AppEnv.betaAllAccess, isTrue);
    // Even a cached FREE entitlement is lifted to PRO, billed yearly.
    c.read(entitlementProvider.notifier).hydrate(Entitlement.free);
    expect(c.read(effectivePlanProvider), Plan.pro);
    expect(c.read(billingPeriodProvider), BillingPeriod.yearly);

    for (final Feature f in Feature.values) {
      expect(c.read(featureGateProvider(f)).allowed, isTrue, reason: '$f');
    }
  });
}
