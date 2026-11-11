// The Google Play build after the beta (STORE_BUILD on, BETA_ALL_ACCESS off):
// the free plan's limits apply, the account's plan comes from the server, and
// nothing sells, prices or links to a payment.
//
// These checks only mean something with those build settings, so they run
// when the suite is started with them (CI does) and are skipped otherwise:
//   flutter test --dart-define=STORE_BUILD=true \
//     --dart-define=BETA_ALL_ACCESS=false test/store_free_mode_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/plans_page.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_popup.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget _app(Widget home, {List<Override> overrides = const <Override>[]}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: Scaffold(body: home),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const bool on = AppEnv.storeFreeMode;

  test('the mode is what the build settings say', () {
    expect(AppEnv.storeFreeMode, AppEnv.storeBuild && !AppEnv.betaAllAccess);
  }, skip: !on);

  group('the plan comes from the account, not from the build', () {
    test('a free account is on the free plan', () {
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        remoteEntitlementProvider
            .overrideWith((Ref ref) async => Entitlement.free),
      ]);
      addTearDown(c.dispose);
      expect(c.read(effectivePlanProvider), Plan.free);
    }, skip: !on);

    test('an account with Pro (bought on the website) has Pro here', () async {
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        remoteEntitlementProvider.overrideWith(
            (Ref ref) async => const Entitlement(plan: Plan.pro)),
      ]);
      addTearDown(c.dispose);
      await c.read(remoteEntitlementProvider.future);
      expect(c.read(effectivePlanProvider), Plan.pro);
    }, skip: !on);

    test('the free plan limits apply (a daret, a goal...)', () {
      expect(
          FeatureGate.evaluate(Feature.goals, plan: Plan.free, used: 2).allowed,
          isFalse);
      expect(
          FeatureGate.evaluate(Feature.goals, plan: Plan.pro, used: 2).allowed,
          isTrue);
    }, skip: !on);
  });

  group('nothing sells', () {
    testWidgets('the plans page is a plain note: no price, no buy button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(_app(const PlansPage(), overrides: <Override>[
        remoteEntitlementProvider
            .overrideWith((Ref ref) async => Entitlement.free),
      ]));
      await tester.pump();
      expect(find.text('Pro features'), findsOneWidget);
      expect(find.textContaining('Some features are part of the Pro plan'),
          findsOneWidget);
      for (final String bad in <String>[
        r'$',
        'per month',
        'per year',
        'Upgrade',
        'Subscribe',
        'coupon',
        'Coupon',
        'trial',
        'Manage',
      ]) {
        expect(find.textContaining(bad), findsNothing, reason: bad);
      }
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    }, skip: !on);

    testWidgets('the upgrade pop-up is a note with one way out',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(_app(Builder(
          builder: (BuildContext context) => TextButton(
              onPressed: () => UpgradePopup.show(context),
              child: const Text('open')))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Pro features'), findsOneWidget);
      expect(find.textContaining('sign in with it'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.text('Upgrade now'), findsNothing);
    }, skip: !on);

    testWidgets('a reached limit says what Pro lifts, with no button to plans',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final GateDecision d =
          FeatureGate.evaluate(Feature.goals, plan: Plan.free, used: 2);
      await tester.pumpWidget(_app(UpgradeSheet(decision: d)));
      await tester.pump();
      expect(find.textContaining('A Pro account has no limit here'),
          findsOneWidget);
      expect(find.text('See plans'), findsNothing);
      expect(find.textContaining('Upgrade to'), findsNothing);
      expect(find.text('Not now'), findsOneWidget);
    }, skip: !on);
  });
}
