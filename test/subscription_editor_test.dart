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
import 'package:smartbudget/features/subscriptions/domain/subscription_cancel.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_payments.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
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

  test('cancelled: the rule stops; active again: it starts from the next date',
      () async {
    final SubscriptionActions a = c.read(subscriptionActionsProvider);
    final DateTime now = AppClock.now();
    final Subscription s = Subscription(
      id: 'sub-x',
      ruleId: 'sub-x',
      kind: SubscriptionKind.digital,
      provider: 'Netflix',
      createdAt: now,
      updatedAt: now,
    );
    await a.save(s,
        amount: const Money(1500, 'USD'),
        frequency: RecurrenceFrequency.monthly,
        nextCharge: DateTime(_today().year, _today().month, _today().day + 3));
    // The repository's list: the provider's may lag a change just made.
    Future<RecurringRule> rule() async {
      await c.read(recurringRulesProvider.future); // loaded
      return c
          .read(recurringRepositoryProvider)
          .current
          .singleWhere((RecurringRule r) => r.id == 'sub-x');
    }

    final Subscription asked = await a.cancel(
        (sub: s, rule: await rule()), CancelOutcome.requested);
    expect(asked.status, SubscriptionStatus.cancelRequested);
    // Only asked: it may still be charged, so the rule keeps going.
    expect((await rule()).active, isTrue);

    final Subscription until = await a.cancel(
        (sub: asked, rule: await rule()), CancelOutcome.activeUntilEnd,
        paidUntil: DateTime(_today().year, _today().month, _today().day + 3));
    expect(until.status, SubscriptionStatus.activeUntilEnd);
    expect((await rule()).active, isFalse);

    // Editing it keeps it stopped.
    await a.save(until,
        amount: const Money(1700, 'USD'),
        frequency: RecurrenceFrequency.monthly,
        nextCharge: DateTime(_today().year, _today().month, _today().day + 3));
    expect((await rule()).active, isFalse);
    expect((await rule()).amount.minorUnits, 1700);

    final Subscription back = await a.cancel(
        (sub: until, rule: await rule()), CancelOutcome.reactivated);
    expect(back.status, SubscriptionStatus.active);
    expect((await rule()).active, isTrue);
    expect((await c.read(subscriptionStoreProvider).all()).single.status,
        SubscriptionStatus.active);
  });

  test('"keep it" silences reminders for that charge', () async {
    final SubscriptionActions a = c.read(subscriptionActionsProvider);
    final DateTime now = AppClock.now();
    final Subscription s = Subscription(
      id: 'sub-k',
      ruleId: 'sub-k',
      kind: SubscriptionKind.digital,
      provider: 'Spotify',
      createdAt: now,
      updatedAt: now,
    );
    await a.save(s,
        amount: const Money(999, 'USD'),
        frequency: RecurrenceFrequency.monthly,
        nextCharge: DateTime(2030, 1, 15));
    await a.keepUntil(s, DateTime(2030, 1, 15, 10));
    expect((await c.read(subscriptionStoreProvider).all()).single.keptUntil,
        DateTime(2030, 1, 15));
  });

  group('Was it charged?', () {
    Future<SubscriptionItem> added(String id, DateTime next) async {
      final SubscriptionActions a = c.read(subscriptionActionsProvider);
      final DateTime now = AppClock.now();
      final Subscription s = Subscription(
        id: id,
        ruleId: id,
        kind: SubscriptionKind.digital,
        provider: 'Netflix',
        createdAt: now,
        updatedAt: now,
      );
      await a.save(s,
          amount: const Money(1500, 'USD'),
          frequency: RecurrenceFrequency.monthly,
          nextCharge: next);
      await c.read(recurringRulesProvider.future);
      return (
        sub: s,
        rule: c
            .read(recurringRepositoryProvider)
            .current
            .singleWhere((RecurringRule r) => r.id == id),
      );
    }

    test('yes: one expense, recorded once even if answered twice', () async {
      final DateTime today = _today();
      final SubscriptionItem i = await added('sub-y', today);
      final SubscriptionActions a = c.read(subscriptionActionsProvider);
      await a.confirmCharge(i, today, const Money(1620, 'USD'));
      await a.confirmCharge(i, today, const Money(1620, 'USD'));
      final List<Transaction> all =
          c.read(financeRepositoryProvider).current;
      final List<Transaction> mine = all
          .where((Transaction t) => t.description == 'Netflix')
          .toList();
      expect(mine, hasLength(1));
      expect(mine.single.amount.minorUnits, 1620);
      expect(mine.single.category, subscriptionCategory);
      final Subscription s =
          (await c.read(subscriptionStoreProvider).all()).single;
      expect(s.payments.values.single, mine.single.id);
      final RecurringRule r = c
          .read(recurringRepositoryProvider)
          .current
          .singleWhere((RecurringRule r) => r.id == 'sub-y');
      // Answered; the usual amount stays (not asked to change it).
      expect(r.lastPosted, today);
      expect(r.amount.minorUnits, 1500);
    });

    test('a new amount for the next renewals when asked', () async {
      final DateTime today = _today();
      final SubscriptionItem i = await added('sub-z', today);
      await c
          .read(subscriptionActionsProvider)
          .confirmCharge(i, today, const Money(1700, 'USD'), forFuture: true);
      expect(
          c
              .read(recurringRepositoryProvider)
              .current
              .singleWhere((RecurringRule r) => r.id == 'sub-z')
              .amount
              .minorUnits,
          1700);
    });

    test('recorded by hand: linked, nothing new written', () async {
      final DateTime today = _today();
      final SubscriptionItem i = await added('sub-m', today);
      final Transaction own = Transaction(
        id: 'own-1',
        date: today,
        type: TransactionType.expense,
        category: 'x',
        amount: const Money(1500, 'USD'),
        createdAt: today,
      );
      await c.read(financeRepositoryProvider).importMany(<Transaction>[own]);
      final int before = c.read(financeRepositoryProvider).current.length;
      await c.read(subscriptionActionsProvider).linkCharge(i, today, own);
      expect(c.read(financeRepositoryProvider).current.length, before);
      expect((await c.read(subscriptionStoreProvider).all()).single.payments,
          <String, String>{SubscriptionPayments.key(today): 'own-1'});
    });

    test('not charged: nothing recorded, the question goes', () async {
      final DateTime today = _today();
      final SubscriptionItem i = await added('sub-n', today);
      final int before = c.read(financeRepositoryProvider).current.length;
      await c.read(subscriptionActionsProvider).skipCharge(i, today);
      expect(c.read(financeRepositoryProvider).current.length, before);
      final RecurringRule r = c
          .read(recurringRepositoryProvider)
          .current
          .singleWhere((RecurringRule r) => r.id == 'sub-n');
      expect(SubscriptionPayments.due(r, AppClock.now()), isEmpty);
    });
  });
}
