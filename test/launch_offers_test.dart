import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/data/checkout_service.dart';
import 'package:smartbudget/features/billing/data/subscription_service.dart';
import 'package:smartbudget/features/billing/data/trial_service.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/founding_offer.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/domain/user_subscription.dart';
import 'package:smartbudget/features/billing/presentation/plans_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(id: 'u1', email: 'a@test'));
}

final FoundingOffer _offer =
    FoundingOffer(yearlyUsd: 39.99, endsAt: DateTime.utc(2099, 12, 31, 12));

/// The plans page while plans are on sale (payment test mode), signed in.
Widget _host({Entitlement? entitlement, FoundingOffer? offer}) => ProviderScope(
      overrides: <Override>[
        paymentTestModeProvider.overrideWith((_) async => true),
        subscriptionProvider
            .overrideWith((_) async => null as UserSubscription?),
        foundingOfferProvider.overrideWith((_) async => offer),
        enabledProvidersProvider
            .overrideWith((_) async => const <PayProvider>[PayProvider.whop]),
        remoteEntitlementProvider.overrideWith((_) async => entitlement),
        authControllerProvider.overrideWith(_SignedIn.new),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            DsColors.light,
            DsGlass.light
          ],
        ),
        home: const Scaffold(body: PlansPage()),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('founding offer', () {
    test('read from the server, only while it runs', () {
      final FoundingOffer? o = FoundingOffer.fromJson(<String, Object?>{
        'yearlyUsd': 39.99,
        'endsAt': '2026-12-31T23:59:59Z'
      });
      expect(o?.yearlyUsd, 39.99);
      expect(o!.activeAt(DateTime.utc(2026, 12, 1)), isTrue);
      expect(o.activeAt(DateTime.utc(2027, 1, 1)), isFalse);
      expect(FoundingOffer.fromJson(null), isNull);
      expect(
          FoundingOffer.fromJson(
              <String, Object?>{'yearlyUsd': 0, 'endsAt': '2026-12-31'}),
          isNull);
      expect(FoundingOffer.fromJson(<String, Object?>{'yearlyUsd': 39.99}),
          isNull);
    });

    testWidgets('the Pro card shows the first-year price and its end date',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester
          .pumpWidget(_host(entitlement: const Entitlement(), offer: _offer));
      await tester.pumpAndSettle();
      expect(find.text('\u2066\$39.99\u2069 the first year, then \u2066\$59.99\u2069 / yr'),
          findsOneWidget);
      expect(find.textContaining('Launch offer until'), findsOneWidget);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('choosing yearly during the offer says what is charged',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester
          .pumpWidget(_host(entitlement: const Entitlement(), offer: _offer));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Upgrade'));
      await tester.pumpAndSettle();
      expect(find.text('\u2066\$39.99\u2069 the first year, then \u2066\$59.99\u2069 / yr'),
          findsNWidgets(2));
      expect(find.text('Launch offer'), findsOneWidget);
    });

    testWidgets('no offer: the regular yearly price and its saving',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester.pumpWidget(_host(entitlement: const Entitlement()));
      await tester.pumpAndSettle();
      expect(find.text(r'$59.99 / yr'), findsOneWidget);
      expect(find.text('Save 50%'), findsOneWidget);
      expect(find.textContaining('Launch offer'), findsNothing);
    });
  });

  group('free trial', () {
    test('the server refusal is told apart', () {
      expect(TrialService.errorFrom('trial_used'), TrialError.used);
      expect(TrialService.errorFrom('already_paid'), TrialError.paid);
      expect(TrialService.errorFrom('timeout'), TrialError.network);
    });

    test('whether the trial was used is kept with the plan', () {
      const Entitlement e = Entitlement(trialUsed: true);
      expect(Entitlement.fromJson(e.toJson()).trialUsed, isTrue);
      expect(Entitlement.fromJson(const Entitlement().toJson()).trialUsed,
          isFalse);
    });

    testWidgets('a FREE account that never tried Pro is offered the trial',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester.pumpWidget(_host(entitlement: const Entitlement()));
      await tester.pumpAndSettle();
      expect(find.text('Try Pro free for 14 days'), findsOneWidget);
      expect(find.text('Start free trial'), findsOneWidget);
    });

    testWidgets('a used trial is not offered again',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester
          .pumpWidget(_host(entitlement: const Entitlement(trialUsed: true)));
      await tester.pumpAndSettle();
      expect(find.text('Start free trial'), findsNothing);
    });

    testWidgets('during the trial: its end date, and Pro can still be bought',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester.pumpWidget(_host(
          entitlement: Entitlement(
              trialPlan: Plan.pro,
              trialExpiresAt: DateTime.utc(2099, 1, 15, 12),
              trialUsed: true)));
      await tester.pumpAndSettle();
      expect(find.text("You're trying Pro until \u20662099-01-15\u2069"), findsOneWidget);
      expect(find.text('Start free trial'), findsNothing);
      expect(find.textContaining('Upgrade'), findsOneWidget);
    });

    testWidgets('a paying account sees no trial', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester
          .pumpWidget(_host(entitlement: const Entitlement(plan: Plan.pro)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Try Pro free'), findsNothing);
    });
  });
}
