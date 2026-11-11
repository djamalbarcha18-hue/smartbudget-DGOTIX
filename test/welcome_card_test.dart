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
    {bool income = false,
    bool tx = false,
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
          hasIncome: income,
          hasExpense: tx,
          hasBudget: budget,
          hasGoal: goal)),
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

  Finder next(String label) => find.descendant(
      of: find.byKey(const ValueKey<String>('onb-next')),
      matching: find.text(label));

  testWidgets('a new user is offered one thing: their income',
      (WidgetTester tester) async {
    await _pump(tester);
    expect(next('Add your income'), findsOneWidget);
    expect(find.text('or record an expense'), findsOneWidget);
    expect(find.text('0 of 4 done'), findsOneWidget);
    // The currency is said on the card, with a way to change it.
    expect(find.text('Your currency: DZD'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    // The guide is a link, not a step to tick.
    expect(find.byKey(const ValueKey<String>('onb-guide')), findsOneWidget);
    expect(find.text('Choose your language and base currency'), findsNothing);
  });

  testWidgets('with the income in, the first expense is next',
      (WidgetTester tester) async {
    await _pump(tester, income: true);
    expect(find.text('Well done! Your first entry is saved'), findsOneWidget);
    expect(next('Record your first expense'), findsOneWidget);
    expect(find.text('1 of 4 done'), findsOneWidget);
    // The currency line and the other way in belong to the very start only.
    expect(find.byKey(const ValueKey<String>('onb-currency')), findsNothing);
    expect(find.byKey(const ValueKey<String>('onb-expense')), findsNothing);
  });

  testWidgets('an expense recorded first: the income is still asked for',
      (WidgetTester tester) async {
    await _pump(tester, tx: true);
    expect(next('Add your income'), findsOneWidget);
    expect(find.text('1 of 4 done'), findsOneWidget);
  });

  testWidgets('income and expense in: the budget, then the goal',
      (WidgetTester tester) async {
    await _pump(tester, income: true, tx: true);
    expect(next('Set a monthly budget'), findsOneWidget);
    expect(find.text('2 of 4 done'), findsOneWidget);
    await _pump(tester, income: true, tx: true, budget: true);
    expect(next('Create a savings goal'), findsOneWidget);
    expect(find.text('3 of 4 done'), findsOneWidget);
  });

  testWidgets('not for this user: nothing is drawn',
      (WidgetTester tester) async {
    await _pump(tester, visible: false);
    expect(find.byKey(const ValueKey<String>('onb-next')), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
