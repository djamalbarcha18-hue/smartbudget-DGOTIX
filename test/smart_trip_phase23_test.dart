import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/share/presentation/share_card_skin.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/data/trip_image_share.dart';
import 'package:smartbudget/features/trips/data/trip_photos.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_editor_sheet.dart';
import 'package:smartbudget/features/trips/presentation/trip_home_card.dart';
import 'package:smartbudget/features/trips/presentation/trip_share_card.dart';
import 'package:smartbudget/features/trips/presentation/trip_share_page.dart';
import 'package:smartbudget/features/trips/presentation/trip_summary_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// How the app writes [dollars] (with its direction marks).
String usd(int dollars) => MoneyFormatter.format(Money(dollars * 100, 'USD'));

void main() {
  // No destination pictures are in the app yet: icons only.
  final DestinationCatalog catalog = DestinationCatalog.fromJson(
      File('assets/data/destinations.json').readAsStringSync(),
      bundled: <String>{});
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  Trip trip(String id,
          {int from = -2,
          int to = 4,
          int? budget,
          String place = 'Istanbul',
          int travelers = 1,
          String? goalId}) =>
      Trip(
        id: id,
        name: 'Trip $id',
        destination: place,
        start: today.add(Duration(days: from)),
        end: today.add(Duration(days: to)),
        plannedBudget: budget == null ? null : Money(budget * 100, 'USD'),
        createdAt: DateTime(2026),
        travelers: travelers,
        goalId: goalId,
      );

  Transaction spend(String id, int amount,
          {String tripId = 'a', String cat = 'المطاعم', int day = 0}) =>
      Transaction(
        id: id,
        date: today.add(Duration(days: day)),
        type: TransactionType.expense,
        category: cat,
        amount: Money(amount * 100, 'USD'),
        tripId: tripId,
        createdAt: DateTime(2026),
      );

  // 5 expenses: 300 food, 500 stay, 50 taxi … = 1,320 of 1,500.
  final List<Transaction> five = <Transaction>[
    spend('1', 300, cat: 'المطاعم', day: -2),
    spend('2', 500, cat: 'السكن', day: -2),
    spend('3', 50, cat: 'النقل', day: -1),
    spend('4', 400, cat: 'التسوق', day: -1),
    spend('5', 70, cat: 'المطاعم'),
  ];

  group('home card: one state, set by the dates', () {
    test('planning, under way, summary ready — then gone after 14 days', () {
      expect(
          TripMath.status(trip('a', from: 5, to: 9), now), TripStatus.upcoming);
      expect(TripMath.status(trip('a'), now), TripStatus.active);
      expect(
          TripMath.status(trip('a', from: -9, to: -3), now), TripStatus.ended);
      expect(TripDashboard.pick(<Trip>[trip('a', from: -20, to: -14)], now),
          isNotNull,
          reason: 'ended 14 days ago: still shown');
      expect(TripDashboard.pick(<Trip>[trip('a', from: -20, to: -15)], now),
          isNull,
          reason: '15 days: only in the trips list');
      expect(TripDashboard.pick(const <Trip>[], now), isNull);
    });

    test('two trips: the one closest in time', () {
      final Trip older = trip('old', from: -5, to: 5);
      final Trip newer = trip('new', from: -1, to: 2);
      final Trip next = trip('next', from: 3, to: 6);
      final Trip later = trip('later', from: 30, to: 36);
      final Trip ended = trip('ended', from: -9, to: -3);
      expect(TripDashboard.pick(<Trip>[older, newer, next], now)!.id, 'new');
      expect(TripDashboard.pick(<Trip>[later, ended, next], now)!.id, 'next');
      expect(TripDashboard.pick(<Trip>[ended], now)!.id, 'ended');
    });

    test('day X of Y, what is left per day, spent today', () {
      final Trip t = trip('a', from: -2, to: 4, budget: 1500); // 7 days
      expect(TripDays.total(t), 7);
      expect(TripDays.dayNumber(t, now), 3);
      final TripReport r = TripReport.of(t, five, now, currency: 'USD');
      expect(r.spent, const Money(132000, 'USD'));
      // 180 left over 5 days (today included) = 36 a day.
      expect(TripDashboard.dailyAvailable(r, now), const Money(3600, 'USD'));
      expect(
          TripDashboard.spentOn(t, five, now, 'USD'), const Money(7000, 'USD'));
      final TripReport over =
          TripReport.of(trip('a', budget: 1000), five, now, currency: 'USD');
      expect(TripDashboard.dailyAvailable(over, now), const Money(0, 'USD'));
    });
  });

  group('the numbers', () {
    test('with a budget: used, saved, average, biggest category', () {
      final TripReport r = TripReport.of(
          trip('a', from: -9, to: -3, budget: 1500, travelers: 2), five, now,
          currency: 'USD');
      expect(r.usedPct, 88);
      expect(r.underBudget, isTrue);
      expect(r.savedPct, 12);
      expect(r.difference, const Money(18000, 'USD'));
      expect(r.dailyAverage, const Money(18857, 'USD')); // 1,320 / 7
      expect(r.perPerson, const Money(66000, 'USD'));
      expect(r.top!.category, 'السكن');
      expect(r.categories.map((TripCategoryShare c) => c.category),
          <String>['السكن', 'التسوق', 'المطاعم', 'النقل']);
    });

    test('no budget: no comparison and no badge', () {
      final TripReport r = TripReport.of(trip('a'), five, now, currency: 'USD');
      expect(r.hasBudget, isFalse);
      expect(r.usedPct, isNull);
      expect(r.savedPct, isNull);
      expect(r.underBudget, isFalse);
      expect(TripDashboard.dailyAvailable(r, now), isNull);
    });

    test('over budget: no "you saved"', () {
      final TripReport r =
          TripReport.of(trip('a', budget: 1000), five, now, currency: 'USD');
      expect(r.savedPct, isNull);
      expect(r.overPct, 32);
    });

    test('no expenses', () {
      final TripReport r = TripReport.of(
          trip('a', budget: 900), const <Transaction>[], now,
          currency: 'USD');
      expect(r.hasExpenses, isFalse);
      expect(r.top, isNull);
    });

    test('monthly saving: (target − saved) ÷ months left', () {
      final Trip t = trip('a', from: 95, to: 100, budget: 1500); // 3 months
      Goal goal(int saved) => Goal(
            id: 'g',
            name: 'g',
            target: const Money(150000, 'USD'),
            saved: Money(saved * 100, 'USD'),
            createdAt: DateTime(2026),
          );
      expect(TripDashboard.monthlyNeeded(goal(300), t, now),
          const Money(40000, 'USD'));
      expect(TripDashboard.monthlyNeeded(goal(1500), t, now), isNull,
          reason: 'goal reached');
      expect(TripDashboard.monthlyNeeded(goal(0), trip('a', from: 20), now),
          isNull,
          reason: 'too close');
    });
  });

  // 1,000 in and 600 out in each of the last three months: 400 a month.
  List<Transaction> history() => <Transaction>[
        for (int back = 1; back <= 3; back++) ...<Transaction>[
          Transaction(
            id: 'in$back',
            date: DateTime(now.year, now.month - back, 5),
            type: TransactionType.income,
            category: 'راتب أساسي',
            amount: const Money(100000, 'USD'),
            createdAt: DateTime(2026),
          ),
          Transaction(
            id: 'out$back',
            date: DateTime(now.year, now.month - back, 9),
            type: TransactionType.expense,
            category: 'السكن',
            amount: const Money(60000, 'USD'),
            createdAt: DateTime(2026),
          ),
        ],
      ];

  group('budget hint from the usual surplus', () {
    test('average surplus, what it puts aside, whether a budget fits', () {
      final TripBudgetAdvice a = TripBudgetAdvice.of(
          history(), 'USD', now, today.add(const Duration(days: 95)))!;
      expect(a.monthsCounted, 3);
      expect(a.monthlySurplus, const Money(40000, 'USD'));
      expect(a.monthsLeft, 3);
      expect(a.canSave, const Money(120000, 'USD'));
      expect(a.suggestedBudget, const Money(120000, 'USD'));
      expect(a.fits(const Money(150000, 'USD')), isFalse);
      expect(a.neededPerMonth(const Money(150000, 'USD')),
          const Money(50000, 'USD'));
      expect(a.fits(const Money(90000, 'USD')), isTrue);
    });

    test('no history: no hint; no surplus: nothing to suggest', () {
      expect(TripBudgetAdvice.of(const <Transaction>[], 'USD', now, today),
          isNull);
      final List<Transaction> losing = <Transaction>[
        Transaction(
          id: 'x',
          date: DateTime(now.year, now.month - 1, 3),
          type: TransactionType.expense,
          category: 'السكن',
          amount: const Money(50000, 'USD'),
          createdAt: DateTime(2026),
        ),
      ];
      final TripBudgetAdvice a = TripBudgetAdvice.of(
          losing, 'USD', now, today.add(const Duration(days: 90)))!;
      expect(a.hasSurplus, isFalse);
      expect(a.canSave, isNull);
      expect(a.suggestedBudget, isNull);
    });

    test('a trip within a month: no monthly figures', () {
      final TripBudgetAdvice a = TripBudgetAdvice.of(
          history(), 'USD', now, today.add(const Duration(days: 10)))!;
      expect(a.monthsLeft, 0);
      expect(a.canSave, isNull);
      expect(a.fits(const Money(100000, 'USD')), isNull);
    });
  });

  // ---- Screens ---------------------------------------------------------------

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Map<String, Object> stored(List<Trip> trips, List<Transaction> txns) =>
      <String, Object>{
        'sb_trips_guest':
            jsonEncode(trips.map((Trip t) => t.toJson()).toList()),
        'sb_txns_guest':
            jsonEncode(txns.map((Transaction t) => t.toJson()).toList()),
        'sb_base_currency': 'USD',
      };

  Future<ProviderContainer> pump(WidgetTester tester, Widget child,
      {Locale locale = const Locale('en'),
      bool dark = false,
      Size size = const Size(390, 844),
      Map<String, Object> prefs = const <String, Object>{},
      List<Override> overrides = const <Override>[]}) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      destinationCatalogProvider.overrideWith((_) async => catalog),
      ...overrides,
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          extensions: <ThemeExtension<dynamic>>[
            if (dark) DsColors.dark else DsColors.light,
            if (dark) DsGlass.dark else DsGlass.light,
          ],
        ),
        home: Scaffold(body: child),
      ),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  group('home card', () {
    testWidgets(
        'planning with a budget offers to start saving, then shows '
        'the goal', (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs: stored(<Trip>[trip('a', from: 95, to: 100, budget: 1500)],
              const <Transaction>[]));
      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('in 95 days'), findsOneWidget);
      await tester.tap(find.text('Start saving for this trip'));
      await tester.pumpAndSettle();
      final List<Goal> goals = await c.read(goalsProvider.future);
      expect(goals.single.target, const Money(150000, 'USD'));
      expect(goals.single.deadline, today.add(const Duration(days: 95)));
      expect((await c.read(tripStoreProvider).all()).single.goalId,
          goals.single.id);
      expect(find.text('Save ${usd(500)} a month to be ready'), findsOneWidget);
    });

    testWidgets('under way: day, spent of budget, per day, today, add',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs: stored(<Trip>[trip('a', budget: 1500)], five));
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Day 3 of 7'), findsOneWidget);
      expect(find.text('${usd(1320)} of ${usd(1500)}'), findsOneWidget);
      expect(find.text(usd(36)), findsOneWidget);
      expect(find.text(usd(70)), findsOneWidget);
      expect(find.text('Add an expense'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('no budget: no bars, only the spending',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs: stored(<Trip>[trip('a')], five));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Available per day'), findsNothing);
      expect(find.text(usd(1320)), findsOneWidget);
    });

    testWidgets('ended: summary ready', (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs:
              stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five));
      expect(find.text('Your trip summary is ready'), findsOneWidget);
      expect(find.text('You saved 12%'), findsOneWidget);
      expect(find.text('View summary'), findsOneWidget);
    });

    testWidgets('no trip: a small "New trip" button',
        (WidgetTester tester) async {
      await pump(tester, const TripHomeCard());
      expect(find.text('New trip'), findsOneWidget);
    });

    for (final bool dark in <bool>[false, true]) {
      testWidgets('follows the ${dark ? 'dark' : 'light'} theme',
          (WidgetTester tester) async {
        await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
            dark: dark,
            locale: const Locale('ar'),
            prefs: stored(<Trip>[trip('a', budget: 1500)], five));
        expect(find.text('جارية'), findsOneWidget);
        expect(Theme.of(tester.element(find.text('جارية'))).brightness,
            dark ? Brightness.dark : Brightness.light);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('summary', () {
    testWidgets('values, then percentages only', (WidgetTester tester) async {
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          prefs: stored(
              <Trip>[trip('a', from: -9, to: -3, budget: 1500, travelers: 2)],
              five));
      expect(find.text(usd(1320)), findsWidgets);
      expect(find.text('${usd(660)} per person'), findsOneWidget);
      expect(find.text('You saved 12%'), findsOneWidget);
      await tester.tap(find.text('Percentage'));
      await tester.pumpAndSettle();
      expect(find.textContaining('\$'), findsNothing,
          reason: 'no amount in percentage mode');
      expect(find.text('You used 88% of the budget'), findsOneWidget);
    });

    testWidgets('over budget: a neutral phrase, not "you saved"',
        (WidgetTester tester) async {
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          prefs: stored(<Trip>[trip('a', budget: 1000)], five));
      expect(find.text('What a lovely trip'), findsOneWidget);
      expect(find.textContaining('You saved'), findsNothing);
    });

    testWidgets('no expenses: one sentence, add, sharing off',
        (WidgetTester tester) async {
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          prefs: stored(<Trip>[trip('a', budget: 900)], const <Transaction>[]));
      expect(find.text('No expenses are linked to this trip yet.'),
          findsOneWidget);
      expect(find.text('Add an expense'), findsOneWidget);
      expect(find.text('Share your trip'), findsNothing);
    });

    testWidgets('shared only once the trip is over',
        (WidgetTester tester) async {
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          prefs: stored(<Trip>[trip('a', budget: 1500)], five)); // under way
      expect(find.text('Share your trip'), findsNothing);
    });

    testWidgets('an ended trip: share opens the preview',
        (WidgetTester tester) async {
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          size: const Size(390, 1600),
          prefs:
              stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five));
      await tester.ensureVisible(find.text('Share your trip'));
      await tester.tap(find.text('Share your trip'));
      await tester.pumpAndSettle();
      expect(find.byType(TripSharePage), findsOneWidget);
    });

    for (final (Locale, TextDirection) v in const <(Locale, TextDirection)>[
      (Locale('ar'), TextDirection.rtl),
      (Locale('en'), TextDirection.ltr),
    ]) {
      testWidgets('reads ${v.$2.name} in ${v.$1.languageCode}',
          (WidgetTester tester) async {
        await pump(tester, const TripSummaryPage(tripId: 'a'),
            locale: v.$1, prefs: stored(<Trip>[trip('a', budget: 1500)], five));
        expect(Directionality.of(tester.element(find.byType(TripSummaryPage))),
            v.$2);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('planning a trip', () {
    testWidgets('the surplus hint, a suggestion, and a budget too big',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripEditorSheet()),
          size: const Size(390, 1400),
          prefs: stored(const <Trip>[], history()));
      expect(find.text('Your average monthly surplus: ${usd(400)}'),
          findsOneWidget);
      // Default dates start today: within a month, nothing to put aside.
      expect(find.textContaining('put aside'), findsNothing);
    });

    testWidgets('three months ahead: what it puts aside, suggest, too big',
        (WidgetTester tester) async {
      final Trip far = trip('a', from: 95, to: 100);
      await pump(
          tester, SingleChildScrollView(child: TripEditorSheet(existing: far)),
          size: const Size(390, 1400), prefs: stored(<Trip>[far], history()));
      expect(find.text('By the trip you could put aside about ${usd(1200)}.'),
          findsOneWidget);
      await tester.tap(find.text('Suggest a budget'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '1200'), findsOneWidget);
      expect(find.text('${usd(400)} a month, within your usual surplus.'),
          findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '1200'), '3000');
      await tester.pumpAndSettle();
      expect(
          find.text(
              'This needs ${usd(1000)} a month, more than your usual surplus.'),
          findsOneWidget);
    });
  });

  group('trip style and days', () {
    test('the style is stored, optional, and kept by other changes', () {
      final Trip t = Trip(
        id: 'a',
        name: 'A',
        destination: 'Rome',
        start: today,
        end: today.add(const Duration(days: 4)),
        createdAt: DateTime(2026),
        level: TripLevel.luxury,
      );
      expect(Trip.fromJson(t.toJson()).level, TripLevel.luxury);
      expect(Trip.fromJson(trip('b').toJson()).level, isNull);
      expect(t.copyWith(goalId: 'g').level, TripLevel.luxury);
    });

    testWidgets('days by the slider, the style, both saved',
        (WidgetTester tester) async {
      final Trip far = trip('a', from: 10, to: 16); // 7 days
      final ProviderContainer c = await pump(
          tester, SingleChildScrollView(child: TripEditorSheet(existing: far)),
          size: const Size(390, 1500),
          locale: const Locale('ar'),
          prefs: stored(<Trip>[far], const <Transaction>[]));
      expect(find.text('عدد الأيام: 7'), findsOneWidget);
      // Drag the slider all the way: 30 days.
      await tester.drag(find.byType(Slider), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('عدد الأيام: 30'), findsOneWidget);
      await tester.tap(find.text('فاخر'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('حفظ'));
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      final Trip saved = (await c.read(tripStoreProvider).all()).single;
      expect(TripDays.total(saved), 30);
      expect(saved.start, far.start);
      expect(saved.level, TripLevel.luxury);
    });

    testWidgets('shown on the summary', (WidgetTester tester) async {
      final Trip t = Trip(
        id: 'a',
        name: 'Trip a',
        destination: 'Istanbul',
        start: today.subtract(const Duration(days: 9)),
        end: today.subtract(const Duration(days: 3)),
        createdAt: DateTime(2026),
        level: TripLevel.standard,
      );
      await pump(tester, const TripSummaryPage(tripId: 'a'),
          prefs: stored(<Trip>[t], five));
      expect(find.text('Mid-range'), findsOneWidget);
    });
  });

  group('sharing at the right moment', () {
    testWidgets('the "summary ready" card offers to share in one tap',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs:
              stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five));
      expect(find.text('Share your trip'), findsOneWidget);
      await tester.tap(find.text('Share your trip'));
      await tester.pumpAndSettle();
      expect(find.byType(TripSharePage), findsOneWidget);
    });

    testWidgets('no expenses: nothing to share yet',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripHomeCard()),
          prefs: stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)],
              const <Transaction>[]));
      expect(find.text('Share your trip'), findsNothing);
    });
  });

  group('once shared, the summary leaves the home screen', () {
    test('a shared trip is no longer offered; the mark is kept', () {
      final Trip ended = trip('a', from: -9, to: -3, budget: 1500);
      expect(TripDashboard.pick(<Trip>[ended], now)!.id, 'a');
      final Trip shared = ended.copyWith(sharedAt: DateTime(2026, 10, 20));
      expect(TripDashboard.pick(<Trip>[shared], now), isNull);
      expect(Trip.fromJson(shared.toJson()).sharedAt, DateTime(2026, 10, 20));
      expect(Trip.fromJson(ended.toJson()).sharedAt, isNull);
      expect(shared.copyWith(goalId: 'g').sharedAt, shared.sharedAt);
    });

    for (final (TripShareOutcome, bool) v in const <(TripShareOutcome, bool)>[
      (TripShareOutcome.shared, true),
      (TripShareOutcome.cancelled, false),
      (TripShareOutcome.failed, false),
    ]) {
      testWidgets('share ${v.$1.name}: card ${v.$2 ? 'gone' : 'kept'}',
          (WidgetTester tester) async {
        final ProviderContainer c = await pump(
            tester, const TripSharePage(tripId: 'a'),
            prefs:
                stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five),
            overrides: <Override>[
              tripImageSharerProvider.overrideWithValue((Uint8List png,
                      {required String text, required String filename}) async =>
                  v.$1),
            ]);
        await tester.runAsync(() async {
          await tester.tap(find.text('Share'));
          await Future<void>.delayed(const Duration(milliseconds: 600));
        });
        await tester.pumpAndSettle();
        final Trip saved = (await c.read(tripStoreProvider).all()).single;
        expect(saved.sharedAt != null, v.$2);
        expect(TripDashboard.pick(<Trip>[saved], now) == null, v.$2);
        if (v.$1 == TripShareOutcome.failed) {
          expect(find.text('The image could not be made. Please try again.'),
              findsOneWidget);
        }
      });
    }
  });

  group('share card', () {
    final Directory out = Directory(
        Platform.environment['TRIP_CARD_OUT'] ?? Directory.systemTemp.path);

    Future<Uint8List> capture(WidgetTester tester) async {
      final RenderRepaintBoundary b = tester.renderObject(find
          .ancestor(
              of: find.byType(TripShareCard),
              matching: find.byType(RepaintBoundary))
          .first);
      final Uint8List? png = await tester.runAsync(() async {
        final ui.Image image =
            await b.toImage(pixelRatio: TripShareCard.exportPixelRatio);
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      return png!;
    }

    Future<void> settle(WidgetTester tester) async {
      // Let the QR code (vector) and pictures decode.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
    }

    for (final (String, Locale, int?, bool) v
        in const <(String, Locale, int?, bool)>[
      ('en-budget-values', Locale('en'), 1500, false),
      ('en-budget-percent', Locale('en'), 1500, true),
      ('ar-budget-values', Locale('ar'), 1500, false),
      ('ar-nobudget-percent', Locale('ar'), null, true),
      ('en-nobudget-values', Locale('en'), null, false),
    ]) {
      testWidgets('is 1080 × 1920: ${v.$1}', (WidgetTester tester) async {
        final ProviderContainer c = await pump(
            tester, const TripSharePage(tripId: 'a'),
            locale: v.$2,
            prefs: stored(
                <Trip>[trip('a', from: -9, to: -3, budget: v.$3)], five));
        c.read(tripPercentModeProvider.notifier).state = v.$4;
        await tester.pumpAndSettle();
        await settle(tester);
        expect(tester.takeException(), isNull);
        final Uint8List png = await capture(tester);
        final img.Image decoded = img.decodePng(png)!;
        expect(decoded.width, 1080);
        expect(decoded.height, 1920);
        File('${out.path}/trip-card-${v.$1}.png').writeAsBytesSync(png);
        if (v.$4) {
          expect(
              find.descendant(
                  of: find.byType(TripShareCard),
                  matching: find.textContaining('\$')),
              findsNothing);
        }
        if (v.$2.languageCode == 'en') {
          // The badge is a percentage: shown in both modes, with a budget.
          expect(
              find.descendant(
                  of: find.byType(TripShareCard),
                  matching: find.textContaining('You saved')),
              v.$3 != null ? findsOneWidget : findsNothing);
        }
      });
    }

    testWidgets('the four colours', (WidgetTester tester) async {
      await pump(tester, const TripSharePage(tripId: 'a'),
          prefs: stored(<Trip>[trip('a', from: -9, to: -3)], five));
      for (final TripCardColor k in TripCardColor.values) {
        await tester.tap(find
            .bySemanticsLabel(k.name[0].toUpperCase() + k.name.substring(1)));
        await tester.pumpAndSettle();
        final ColoredBox bg = tester.widget<ColoredBox>(find
            .descendant(
                of: find.byType(TripShareCard),
                matching: find.byType(ColoredBox))
            .first);
        expect(bg.color, k.color);
      }
    });

    testWidgets('Pro theme: the card in its colours first, then a colour',
        (WidgetTester tester) async {
      await pump(tester, const TripSharePage(tripId: 'a'),
          prefs: <String, Object>{
            ...stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five),
            'flutter.sb_theme_style': 'pomegranate',
          },
          overrides: <Override>[
            effectivePlanProvider.overrideWithValue(Plan.pro),
          ]);
      Color background() => tester
          .widget<ColoredBox>(find
              .descendant(
                  of: find.byType(TripShareCard),
                  matching: find.byType(ColoredBox))
              .first)
          .color;
      expect(background(), ShareCardSkin.pomegranate.solid);
      await tester.tap(find.bySemanticsLabel('Blue'));
      await tester.pumpAndSettle();
      expect(background(), TripCardColor.blue.color);
      await tester.tap(find.bySemanticsLabel('In my theme colours'));
      await tester.pumpAndSettle();
      expect(background(), ShareCardSkin.pomegranate.solid);
    });

    testWidgets('with a photo from the gallery, and back to the default',
        (WidgetTester tester) async {
      final Uint8List jpg =
          Uint8List.fromList(img.encodeJpg(img.Image(width: 400, height: 300)));
      await pump(tester, const TripSharePage(tripId: 'a'),
          prefs:
              stored(<Trip>[trip('a', from: -9, to: -3, budget: 1500)], five),
          overrides: <Override>[
            tripPhotoPickerProvider.overrideWithValue(_FakePicker(jpg)),
          ]);
      // The user's photo (the app icon is always there).
      final Finder userPhoto = find.byWidgetPredicate(
          (Widget w) => w is Image && w.image is MemoryImage);
      expect(userPhoto, findsNothing);
      await tester.tap(find.text('From the gallery'));
      await tester.pumpAndSettle();
      expect(userPhoto, findsOneWidget);
      await settle(tester);
      final img.Image decoded = img.decodePng(await capture(tester))!;
      expect((decoded.width, decoded.height), (1080, 1920));
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      expect(userPhoto, findsNothing);
    });

    testWidgets('refused photo access: one sentence',
        (WidgetTester tester) async {
      await pump(tester, const TripSharePage(tripId: 'a'),
          prefs: stored(<Trip>[trip('a', from: -9, to: -3)], five),
          overrides: <Override>[
            tripPhotoPickerProvider
                .overrideWithValue(const _FakePicker(null, denied: true)),
          ]);
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
      expect(
          find.text('To add photos, allow SmartBudget to use your photos or '
              'camera in your phone settings.'),
          findsOneWidget);
    });

    for (final Size size in const <Size>[
      Size(320, 568),
      Size(360, 740),
      Size(412, 915),
      Size(800, 1280),
    ]) {
      testWidgets('fits a ${size.width.toInt()}×${size.height.toInt()} screen',
          (WidgetTester tester) async {
        await pump(tester, const TripSharePage(tripId: 'a'),
            size: size,
            locale: const Locale('ar'),
            prefs: stored(
                <Trip>[trip('a', from: -9, to: -3, budget: 1500, travelers: 3)],
                five));
        expect(tester.takeException(), isNull);
        final Size card = tester.getSize(find.byType(TripShareCard));
        expect(card.width / card.height, closeTo(9 / 16, 0.001));
      });
    }

    group('clear template (paid plan)', () {
      final Uint8List jpg = Uint8List.fromList(img.encodeJpg(img.fill(
          img.Image(width: 600, height: 1066),
          color: img.ColorRgb8(90, 140, 200))));

      testWidgets('free plan: the upgrade sheet, no clear card',
          (WidgetTester tester) async {
        await pump(tester, const TripSharePage(tripId: 'a'),
            prefs: stored(<Trip>[trip('a', from: -9, to: -3)], five),
            overrides: <Override>[
              effectivePlanProvider.overrideWithValue(Plan.free),
              tripPhotoPickerProvider.overrideWithValue(_FakePicker(jpg)),
            ]);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(find.byType(UpgradeSheet), findsOneWidget);
        expect(tester.widget<TripShareCard>(find.byType(TripShareCard)).clear,
            isFalse);
      });

      testWidgets(
          'asks for a photo, then the whole photo, the brand once, '
          '1080 × 1920 with a readable QR', (WidgetTester tester) async {
        await pump(tester, const TripSharePage(tripId: 'a'),
            locale: const Locale('ar'),
            prefs: stored(
                <Trip>[trip('a', from: -9, to: -3, budget: 1500, travelers: 2)],
                five),
            overrides: <Override>[
              effectivePlanProvider.overrideWithValue(Plan.pro),
              tripPhotoPickerProvider.overrideWithValue(_FakePicker(jpg)),
            ]);
        await tester.tap(find.text('شفاف'));
        await tester.pumpAndSettle();
        expect(find.text('أضف صورة لاستخدام القالب الشفاف.'), findsOneWidget);
        final TripShareCard card =
            tester.widget<TripShareCard>(find.byType(TripShareCard));
        expect(card.clear, isTrue);
        expect(card.photo, isNotNull);
        // The colours are for the coloured template only.
        expect(find.bySemanticsLabel('أخضر'), findsNothing);
        // The brand appears once: one app icon, no tag at the top.
        expect(
            find.descendant(
                of: find.byType(TripShareCard),
                matching: find.byWidgetPredicate((Widget w) =>
                    w is Image &&
                    w.image is AssetImage &&
                    (w.image as AssetImage).assetName ==
                        TripShareCard.appIconAsset)),
            findsOneWidget);
        expect(find.text('DGOTIX · SmartBudget'), findsOneWidget);
        await settle(tester);
        expect(tester.takeException(), isNull);
        final Uint8List png = await capture(tester);
        final img.Image decoded = img.decodePng(png)!;
        expect((decoded.width, decoded.height), (1080, 1920));
        File('${out.path}/trip-card-clear-ar.png').writeAsBytesSync(png);
      });

      testWidgets('Black Gold: a touch of gold on the photo, or plain white',
          (WidgetTester tester) async {
        await pump(tester, const TripSharePage(tripId: 'a'),
            prefs: <String, Object>{
              ...stored(
                  <Trip>[trip('a', from: -9, to: -3, budget: 1500)], five),
              'flutter.sb_theme_style': 'black',
            },
            overrides: <Override>[
              effectivePlanProvider.overrideWithValue(Plan.pro),
              tripPhotoPickerProvider.overrideWithValue(_FakePicker(jpg)),
            ]);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        Finder gold() => find.descendant(
            of: find.byType(TripShareCard),
            matching: find.byWidgetPredicate((Widget w) =>
                w is Text && w.style?.color == ShareCardSkin.blackGold.accent));
        // The total in gold; the colours stay hidden.
        expect(gold(), findsOneWidget);
        expect(find.bySemanticsLabel('Green'), findsNothing);
        await tester.tap(find.bySemanticsLabel('White'));
        await tester.pumpAndSettle();
        expect(gold(), findsNothing);
        await tester.tap(find.bySemanticsLabel('In my theme colours'));
        await tester.pumpAndSettle();
        expect(gold(), findsOneWidget);
      });

      testWidgets('back to the default photo: back to colour',
          (WidgetTester tester) async {
        await pump(tester, const TripSharePage(tripId: 'a'),
            prefs: stored(<Trip>[trip('a', from: -9, to: -3)], five),
            overrides: <Override>[
              effectivePlanProvider.overrideWithValue(Plan.pro),
              tripPhotoPickerProvider.overrideWithValue(_FakePicker(jpg)),
            ]);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Default'));
        await tester.pumpAndSettle();
        expect(tester.widget<TripShareCard>(find.byType(TripShareCard)).clear,
            isFalse);
      });
    });

    test('the photo is kept whole; a crop keeps the asked shape', () {
      final Uint8List jpg = Uint8List.fromList(
          img.encodeJpg(img.Image(width: 1080, height: 1440)));
      final img.Image whole = img.decodeJpg(cropToAspect((jpg, null))!)!;
      expect((whole.width, whole.height), (1080, 1440));
      final img.Image out = img.decodeJpg(cropToAspect((jpg, 9 / 16))!)!;
      expect(out.width / out.height, closeTo(9 / 16, 0.01));
      expect(out.height, 1440);
    });

    for (final (bool, String) v in const <(bool, String)>[
      (false, 'colour'),
      (true, 'clear'),
    ]) {
      testWidgets('a post is 1080 × 1350, never stretched (${v.$2})',
          (WidgetTester tester) async {
        // A wide photo: each size takes its middle, keeping its proportions.
        final Uint8List wide = Uint8List.fromList(img.encodeJpg(img.fill(
            img.Image(width: 1080, height: 720),
            color: img.ColorRgb8(200, 120, 60))));
        await pump(tester, const TripSharePage(tripId: 'a'),
            prefs: stored(
                <Trip>[trip('a', from: -9, to: -3, budget: 1500, travelers: 2)],
                five),
            overrides: <Override>[
              effectivePlanProvider.overrideWithValue(Plan.pro),
              tripPhotoPickerProvider.overrideWithValue(_FakePicker(wide)),
            ]);
        expect(find.text('Safe zones'), findsNothing);
        await tester.tap(find.text('From the gallery'));
        await tester.pumpAndSettle();
        if (v.$1) {
          await tester.tap(find.text('Clear'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Post 4:5'));
        await tester.pumpAndSettle();
        final Size card = tester.getSize(find.byType(TripShareCard));
        expect(card.width / card.height, closeTo(4 / 5, 0.001));
        final Image photo = tester.widget<Image>(find.byWidgetPredicate(
            (Widget w) => w is Image && w.image is MemoryImage));
        expect(photo.fit, BoxFit.cover, reason: 'cropped, never stretched');
        await settle(tester);
        expect(tester.takeException(), isNull);
        final img.Image decoded = img.decodePng(await capture(tester))!;
        expect((decoded.width, decoded.height), (1080, 1350));
        File('${out.path}/trip-post-${v.$2}.png')
            .writeAsBytesSync(img.encodePng(decoded));
        // And back to a story.
        await tester.tap(find.text('Story 9:16'));
        await tester.pumpAndSettle();
        final img.Image story = img.decodePng(await capture(tester))!;
        expect((story.width, story.height), (1080, 1920));
      });
    }

    test('refusals are told apart from other failures', () {
      expect(DeviceTripPhotoPicker.isDenial('camera_access_denied'), isTrue);
      expect(DeviceTripPhotoPicker.isDenial('photo_access_denied'), isTrue);
      expect(DeviceTripPhotoPicker.isDenial('invalid_image'), isFalse);
    });
  });
}

class _FakePicker implements TripPhotoPicker {
  const _FakePicker(this.bytes, {this.denied = false});
  final Uint8List? bytes;
  final bool denied;

  @override
  Future<Uint8List?> pick(TripPhotoSource source, {double? aspect}) async {
    if (denied) throw const TripPhotoDenied();
    return bytes;
  }
}
