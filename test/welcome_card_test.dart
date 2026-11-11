import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/onboarding/application/onboarding_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';
import 'package:smartbudget/features/onboarding/presentation/welcome_card.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The card with the checklist in a given state, shown or not.
Future<void> _pump(WidgetTester tester,
    {bool tx = false,
    bool budget = false,
    bool goal = false,
    bool visible = true}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      onboardingStepsProvider.overrideWithValue(buildOnboardingSteps(
          hasTransaction: tx, hasBudget: budget, hasGoal: goal)),
      welcomeVisibleProvider.overrideWithValue(visible),
      baseCurrencyProvider.overrideWith(() => _Dzd()),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SingleChildScrollView(child: WelcomeCard())),
    ),
  ));
  await tester.pump();
}

class _Dzd extends BaseCurrencyController {
  @override
  String build() => 'DZD';
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a new user is offered one thing: the first expense',
      (WidgetTester tester) async {
    await _pump(tester);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey<String>('onb-next')),
            matching: find.text('Record your first expense')),
        findsOneWidget);
    expect(find.text('or add income'), findsOneWidget);
    expect(find.text('0 of 3 done'), findsOneWidget);
    // The currency is said on the card, with a way to change it.
    expect(find.text('Your currency: DZD'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    // The guide is a link, not a step to tick.
    expect(find.byKey(const ValueKey<String>('onb-guide')), findsOneWidget);
    expect(find.text('Choose your language and base currency'), findsNothing);
  });

  testWidgets('after the first entry it congratulates and leads to the budget',
      (WidgetTester tester) async {
    await _pump(tester, tx: true);
    expect(find.text('Well done! Your first entry is saved'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey<String>('onb-next')),
            matching: find.text('Set a monthly budget')),
        findsOneWidget);
    // The currency line belongs to the very first step only.
    expect(find.byKey(const ValueKey<String>('onb-currency')), findsNothing);
    expect(find.text('or add income'), findsNothing);
  });

  testWidgets('with a budget set, the goal is next',
      (WidgetTester tester) async {
    await _pump(tester, tx: true, budget: true);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey<String>('onb-next')),
            matching: find.text('Create a savings goal')),
        findsOneWidget);
    expect(find.text('2 of 3 done'), findsOneWidget);
  });

  testWidgets('not for this user: nothing is drawn',
      (WidgetTester tester) async {
    await _pump(tester, visible: false);
    expect(find.byKey(const ValueKey<String>('onb-next')), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
