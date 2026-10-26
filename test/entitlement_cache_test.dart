import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// The plan kept on the device belongs to the account it was saved for.
void main() {
  Future<Entitlement> cachedFor(String? account, Map<String, Object> prefs,
      {Entitlement? pushed}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      currentAccountIdProvider.overrideWithValue(account),
    ]);
    addTearDown(c.dispose);
    c.read(entitlementProvider);
    if (pushed != null) c.read(entitlementProvider.notifier).hydrate(pushed);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c.read(entitlementProvider);
  }

  final Map<String, Object> proOfA = <String, Object>{
    'sb_entitlement':
        jsonEncode(<String, Object>{'plan': 'pro', 'account': 'a'}),
  };

  test('the account that saved it gets its plan back', () async {
    expect((await cachedFor('a', proOfA)).plan, Plan.pro);
  });

  test('another account on the same device starts on FREE', () async {
    expect((await cachedFor('b', proOfA)).plan, Plan.free);
    expect((await cachedFor(null, proOfA)).plan, Plan.free);
  });

  test('a cache that names no account is not taken over', () async {
    expect(
        (await cachedFor('a', <String, Object>{
          'sb_entitlement': jsonEncode(<String, Object>{'plan': 'pro'}),
        }))
            .plan,
        Plan.free);
  });

  test("the server's answer is never replaced by the cache", () async {
    expect((await cachedFor('a', proOfA, pushed: Entitlement.free)).plan,
        Plan.free);
  });

  test('saving names the account', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      currentAccountIdProvider.overrideWithValue('a'),
    ]);
    addTearDown(c.dispose);
    c
        .read(entitlementProvider.notifier)
        .hydrate(const Entitlement(plan: Plan.pro));
    await Future<void>.delayed(Duration.zero);
    final SharedPreferences p = await SharedPreferences.getInstance();
    final Map<String, dynamic> saved =
        jsonDecode(p.getString('sb_entitlement')!) as Map<String, dynamic>;
    expect(saved['account'], 'a');
    expect(saved['plan'], 'pro');
  });
}
