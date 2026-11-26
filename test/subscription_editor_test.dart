import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_editor_sheet.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscriptions_tab.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget _host(ProviderContainer c, Widget child) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: DsTheme.dark(),
        home: Scaffold(body: child),
      ),
    );

DateTime _today() {
  final DateTime n = AppClock.now();
  return DateTime(n.year, n.month, n.day);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late ProviderContainer c;
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    c = ProviderContainer(overrides: <Override>[
      effectivePlanProvider.overrideWithValue(Plan.free),
    ]);
  });
  tearDown(() => c.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(
        c,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () => SubscriptionEditorSheet.show(context),
              child: const Text('open'),
            ),
          ),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a free trial is saved with its end as the first charge',
      (WidgetTester tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Spot');
    await tester.pump();
    // Picked from the catalog suggestions.
    await tester.tap(find.widgetWithText(ActionChip, 'Spotify'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '9.99');
    await tester.tap(find.text('Free trial').first);
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, '7 days'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'RedotPay');
    await tester.pump();
    // The preview shows the reminders before the trial ends.
    expect(find.textContaining('Reminders on:'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final List<Subscription> subs = await c.read(subscriptionsProvider.future);
    expect(subs, hasLength(1));
    final Subscription s = subs.single;
    expect(s.provider, 'Spotify');
    expect(s.catalogId, 'spotify');
    expect(s.status, SubscriptionStatus.trial);
    expect(s.cardName, 'RedotPay');
    final DateTime end = DateTime(_today().year, _today().month,
        _today().day + 7);
    expect(s.trialEndsAt, end);
    final RecurringRule r = (await c.read(recurringRulesProvider.future))
        .singleWhere((RecurringRule r) => r.id == s.ruleId);
    expect(r.startDate, end);
    expect(r.amount.minorUnits, 999);
    expect(r.variableAmount, isTrue);
    expect(r.isSubscription, isTrue);
  });

  testWidgets('a card number is refused and nothing is saved',
      (WidgetTester tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Netflix');
    await tester.enterText(find.byType(TextFormField).at(1), '15');
    await tester.enterText(
        find.byType(TextFormField).last, '4111 1111 1111 1111');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(
        find.text("This looks like a card number. Enter only the card's name."),
        findsOneWidget);
    expect(await c.read(subscriptionsProvider.future), isEmpty);
  });

  testWidgets('without a date nothing is saved', (WidgetTester tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Netflix');
    await tester.enterText(find.byType(TextFormField).at(1), '15');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(await c.read(subscriptionsProvider.future), isEmpty);
  });

  testWidgets('the list shows each subscription with its card',
      (WidgetTester tester) async {
    final SubscriptionActions a = c.read(subscriptionActionsProvider);
    final DateTime now = AppClock.now();
    await a.save(
      Subscription(
        id: 'sub-nf',
        ruleId: 'sub-nf',
        kind: SubscriptionKind.digital,
        provider: 'Netflix',
        cardName: 'Edahabia',
        createdAt: now,
        updatedAt: now,
      ),
      amount: const Money(1500, 'USD'),
      frequency: RecurrenceFrequency.monthly,
      nextCharge: DateTime(_today().year, _today().month, _today().day + 3),
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(c, const SubscriptionsTab()));
    await tester.pumpAndSettle();
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Edahabia'), findsOneWidget);
    expect(find.textContaining('Next charge:'), findsOneWidget);
  });
}
