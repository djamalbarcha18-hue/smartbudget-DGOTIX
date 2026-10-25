import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/reminders/application/reminder_controller.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/reminders/domain/daily_reminder.dart';
import 'package:smartbudget/features/reminders/presentation/reminder_section.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Transaction _txn(String id, DateTime createdAt) => Transaction(
      id: id,
      date: createdAt,
      type: TransactionType.expense,
      category: 'الطعام',
      amount: const Money(1000, 'USD'),
      createdAt: createdAt,
    );

class _FakeNotifications extends ReminderNotifications {
  _FakeNotifications({this.grant = true});
  final bool grant;
  List<DateTime> scheduled = <DateTime>[];
  String? title;
  bool settingsOpened = false;

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => grant;
  @override
  Future<bool> allowed() async => grant;
  @override
  Future<void> openSystemSettings() async => settingsOpened = true;
  @override
  Future<void> schedule(List<DateTime> times,
      {required String title,
      required String body,
      required String channel}) async {
    scheduled = times;
    this.title = title;
  }

  @override
  Future<void> cancel() async => scheduled = <DateTime>[];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('DailyReminder.plan', () {
    const ReminderSettings on = ReminderSettings(enabled: true);
    final DateTime morning = DateTime(2026, 10, 25, 9);

    test('off: nothing is scheduled', () {
      expect(
          DailyReminder.plan(
              now: morning,
              settings: const ReminderSettings(),
              loggedToday: false),
          isEmpty);
    });

    test('nothing recorded yet: tonight first, then a week ahead', () {
      final List<DateTime> p =
          DailyReminder.plan(now: morning, settings: on, loggedToday: false);
      expect(p.first, DateTime(2026, 10, 25, 21));
      expect(p.length, DailyReminder.daysAhead);
      expect(p.last, DateTime(2026, 10, 31, 21));
    });

    test('already recorded today, or past the time: from tomorrow', () {
      expect(
          DailyReminder.plan(now: morning, settings: on, loggedToday: true)
              .first,
          DateTime(2026, 10, 26, 21));
      expect(
          DailyReminder.plan(
                  now: DateTime(2026, 10, 25, 22),
                  settings: on,
                  loggedToday: false)
              .first,
          DateTime(2026, 10, 26, 21));
    });

    test('the chosen time, across a month end', () {
      final List<DateTime> p = DailyReminder.plan(
          now: DateTime(2026, 10, 31, 8),
          settings: on.copyWith(hour: 7, minute: 30),
          loggedToday: false);
      expect(p.first, DateTime(2026, 11, 1, 7, 30));
    });
  });

  test('what counts as recorded today', () {
    final DateTime now = DateTime(2026, 10, 25, 18);
    expect(DailyReminder.loggedToday(<Transaction>[], now), isFalse);
    expect(
        DailyReminder.loggedToday(
            <Transaction>[_txn('a', DateTime(2026, 10, 24, 23))], now),
        isFalse);
    expect(
        DailyReminder.loggedToday(
            <Transaction>[_txn('b', DateTime(2026, 10, 25, 8))], now),
        isTrue);
    // Posted on its own by a recurring rule: not a sign of recording.
    final String auto =
        RecurrenceEngine.occurrenceId('rule1', DateTime(2026, 10, 25));
    expect(RecurrenceEngine.isRecurring(_txn(auto, now)), isTrue);
    expect(
        DailyReminder.loggedToday(
            <Transaction>[_txn(auto, DateTime(2026, 10, 25, 6))], now),
        isFalse);
  });

  test('settings are kept; the time is written with Latin digits', () async {
    ReminderNotifications.instance = _FakeNotifications();
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(reminderProvider);
    expect(await c.read(reminderProvider.notifier).setEnabled(true), isTrue);
    await c.read(reminderProvider.notifier).setTime(7, 5);
    expect(c.read(reminderProvider).timeLabel, '07:05');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sb_reminder_on'), isTrue);
    expect(prefs.getString('sb_reminder_time'), '07:05');
  });

  test('turning it on fails when the phone blocks notifications', () async {
    ReminderNotifications.instance = _FakeNotifications(grant: false);
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(reminderProvider.notifier).setEnabled(true), isFalse);
    expect(c.read(reminderProvider).enabled, isFalse);
  });

  test('a plan is scheduled, an empty one clears', () async {
    final _FakeNotifications n = _FakeNotifications();
    ReminderNotifications.instance = n;
    await applyReminderPlan(ReminderPlan(
        <DateTime>[DateTime(2026, 10, 25, 21)], 'title', 'body', 'channel'));
    expect(n.scheduled, hasLength(1));
    expect(n.title, 'title');
    await applyReminderPlan(
        const ReminderPlan(<DateTime>[], 'title', 'body', 'channel'));
    expect(n.scheduled, isEmpty);
  });

  testWidgets('the section: switch, time, and a blocked phone',
      (WidgetTester t) async {
    final _FakeNotifications n = _FakeNotifications(grant: false);
    ReminderNotifications.instance = n;
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
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
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: const Scaffold(body: ReminderSection()),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Remind me to record my spending'), findsOneWidget);
    expect(find.text('21:00'), findsNothing);

    // Blocked: it stays off and offers the phone's settings.
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(c.read(reminderProvider).enabled, isFalse);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    await t.tap(find.text('Open settings'));
    expect(n.settingsOpened, isTrue);

    // Allowed: on, with the time shown.
    ReminderNotifications.instance = _FakeNotifications();
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(c.read(reminderProvider).enabled, isTrue);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.textContaining('Notifications are off'), findsNothing);
  });

  testWidgets('a tap on the reminder opens quick entry once',
      (WidgetTester t) async {
    int opened = 0;
    ReminderNotifications.tapped.value = true;
    await t.pumpWidget(MaterialApp(
      home: ReminderTapListener(
        onOpen: (_) => opened++,
        child: const SizedBox(),
      ),
    ));
    await t.pump();
    expect(opened, 1);
    expect(ReminderNotifications.tapped.value, isFalse);
    ReminderNotifications.tapped.value = true;
    await t.pump();
    expect(opened, 2);
  });

  test('only the Android app has reminders', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(ReminderNotifications.supported, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(ReminderNotifications.supported, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
