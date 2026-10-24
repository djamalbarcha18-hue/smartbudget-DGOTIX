import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/presentation/trip_editor_sheet.dart';
import 'package:smartbudget/features/trips/presentation/trips_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  final String raw = File('assets/data/destinations.json').readAsStringSync();
  final DestinationCatalog catalog = DestinationCatalog.fromJson(raw);

  DateTime today() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Trip trip(String id, String place,
          {int from = 0, int to = 5, int created = 0, Money? budget}) =>
      Trip(
        id: id,
        name: 'Trip $id',
        destination: place,
        start: today().add(Duration(days: from)),
        end: today().add(Duration(days: to)),
        plannedBudget: budget,
        createdAt: DateTime(2026, 1, 1).add(Duration(days: created)),
      );

  Transaction expense(String id, int amount, {String? tripId}) => Transaction(
        id: id,
        date: today(),
        type: TransactionType.expense,
        category: 'المطاعم',
        amount: Money(amount * 100, 'USD'),
        tripId: tripId,
        createdAt: DateTime(2026),
      );

  group('destinations', () {
    test('the 15 places in the set order, named in every language', () {
      expect(catalog.all.map((Destination d) => d.id).toList(), <String>[
        'mecca', 'medina', 'bangkok', 'london', 'istanbul', 'dubai', //
        'paris', 'kuala_lumpur', 'rome', 'barcelona', 'marrakech', 'cairo',
        'bali', 'tunis', 'tbilisi',
      ]);
      for (final Destination d in catalog.all) {
        expect(d.names.keys.toSet(),
            <String>{'ar', 'en', 'fr', 'id', 'es', 'tr', 'ms', 'ur'},
            reason: d.id);
        expect(d.image, 'assets/images/destinations/${d.id}.webp');
      }
      expect(catalog.popular().length, 6);
      final Destination london = catalog.byText('London')!;
      expect((london.lat, london.lng), (51.5074, -0.1278));
      expect(london.country, 'GB');
      expect(catalog.byText('Dubai')!.icon, 'skyscraper');
    });

    test('the file, its pictures folder and credits ship with the app', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/data/'));
      expect(pubspec, contains('- assets/images/destinations/'));
      expect(
          File('assets/images/destinations/CREDITS.md').existsSync(), isTrue);
    });

    test('a picture not in the app falls back to the icon', () {
      final DestinationCatalog c = DestinationCatalog.fromJson(raw,
          bundled: <String>{'assets/images/destinations/paris.webp'});
      expect(c.byText('Paris')!.image, isNotNull);
      expect(c.byText('London')!.image, isNull);
    });

    test('search matches every language, ignoring vowel marks and hamzas', () {
      String first(String q) => catalog.search(q).first.id;
      expect(first('اسطنبول'), 'istanbul'); // no hamza
      expect(first('إسْطَنْبُول'), 'istanbul'); // marks
      expect(first('Estambul'), 'istanbul'); // Spanish
      expect(first('İSTANBUL'), 'istanbul'); // Turkish capital İ
      expect(first('mecca'), 'mecca');
      expect(first('makkah'), 'mecca'); // the Malay name / old spelling
      expect(first('مكه'), 'mecca'); // ه for ة
      expect(first('المدينه'), 'medina');
      expect(first('مکہ'), 'mecca'); // Urdu letters
      // French names, accents ignored.
      expect(first('la mecque'), 'mecca');
      expect(first('medine'), 'medina');
      expect(first('Londres'), 'london');
      expect(first('le caire'), 'cairo');
      expect(first('tbilissi'), 'tbilisi');
      expect(first('dubai'), 'dubai'); // Dubaï
      expect(first('paris'), 'paris'); // París in Spanish too
      expect(first('kaherah'), 'cairo'); // Malay
      expect(first('kuala'), 'kuala_lumpur');
      expect(catalog.search('zzz'), isEmpty);
    });

    test('a place reads in the current language', () {
      expect(catalog.display('Istanbul', AppLang.ar), 'إسطنبول');
      expect(catalog.display('إسطنبول', AppLang.tr), 'İstanbul');
      expect(catalog.display('Bergen', AppLang.ar), 'Bergen');
      // Trips saved before the list changed still find their place.
      expect(catalog.byText('Makkah')!.id, 'mecca');
      expect(catalog.display('Madinah', AppLang.ar), 'المدينة المنورة');
    });

    test('typed places are tidied', () {
      expect(PlaceText.clean('  new   york '), 'New York');
      expect(PlaceText.clean('NEW YORK'), 'New York');
      expect(PlaceText.clean('NYC'), 'NYC');
      expect(PlaceText.clean('brooklyn NYC'), 'Brooklyn NYC');
      expect(PlaceText.clean('McAllen'), 'McAllen');
      expect(PlaceText.clean(' شرم   الشيخ '), 'شرم الشيخ');
    });
  });

  group('data', () {
    test('a trip is stored and read back', () {
      final Trip t = trip('a', 'Bergen', budget: const Money(150000, 'EUR'));
      final Trip back = Trip.fromJson(t.toJson());
      expect(back.destination, 'Bergen');
      expect(back.start, t.start);
      expect(back.end, t.end);
      expect(back.plannedBudget, const Money(150000, 'EUR'));
      expect(Trip.fromJson(trip('b', 'Rome').toJson()).plannedBudget, isNull);
    });

    test('existing transactions load with no trip; a trip id round-trips', () {
      final Map<String, dynamic> old = expense('x', 5).toJson()
        ..remove('tripId');
      expect(old.containsKey('tripId'), isFalse);
      expect(Transaction.fromJson(old).tripId, isNull);
      final Transaction tagged = expense('y', 5, tripId: 'trip-1');
      expect(Transaction.fromJson(tagged.toJson()).tripId, 'trip-1');
      expect(tagged.copyWith(clearTrip: true).tripId, isNull);
      expect(tagged.copyWith(notes: 'n').tripId, 'trip-1');
    });

    test('trips are backed up and synced like the other plans', () {
      final BackupData data = BackupData(
        exportedAt: DateTime(2026),
        baseCurrency: 'USD',
        transactions: <Transaction>[expense('t1', 9, tripId: 'a')],
        budgets: const [],
        customIncome: const <String>[],
        customExpense: const <String>[],
        trips: <Trip>[trip('a', 'Rome')],
      );
      final BackupData back =
          BackupCodec.decodeJson(BackupCodec.encodeJson(data));
      expect(back.trips.single.destination, 'Rome');
      expect(back.transactions.single.tripId, 'a');
      expect(SyncMerge.listCollections, contains('trips'));
      expect(SyncMerge.recordsFromBackup(data.toJson())['trips']!.keys,
          <String>['a']);
    });

    test('five tagged expenses add up; others do not count', () {
      final Trip t = trip('a', 'Rome');
      final List<Transaction> txns = <Transaction>[
        for (int i = 1; i <= 5; i++) expense('e$i', 10 * i, tripId: 'a'),
        expense('other', 999),
        expense('elsewhere', 999, tripId: 'b'),
        Transaction(
          id: 'refund',
          date: today(),
          type: TransactionType.income,
          category: 'أخرى',
          amount: const Money(5000, 'USD'),
          tripId: 'a',
          createdAt: DateTime(2026),
        ),
      ];
      expect(TripMath.expensesOf(t, txns).length, 5);
      expect(TripMath.spent(t, txns, 'USD'), const Money(15000, 'USD'));
    });

    test('status, the trip under way, and past places once each', () {
      final DateTime now = DateTime.now();
      final Trip soon = trip('s', 'Bali', from: 3, to: 8, created: 3);
      final Trip on = trip('o', 'Istanbul', from: -2, to: 2, created: 2);
      final Trip done = trip('d', 'إسطنبول', from: -20, to: -15, created: 1);
      final Trip typed = trip('t', 'Bergen', from: -40, to: -35);
      expect(TripMath.status(soon, now), TripStatus.upcoming);
      expect(TripMath.daysUntil(soon, now), 3);
      expect(TripMath.status(on, now), TripStatus.active);
      expect(TripMath.status(done, now), TripStatus.ended);
      final List<Trip> all = <Trip>[soon, on, done, typed];
      expect(TripMath.activeOn(all, now)!.id, 'o');
      expect(TripMath.activeOn(all, now.add(const Duration(days: 10))), isNull);
      expect(
          TripMath.current(all, now).map((Trip x) => x.id), <String>['o', 's']);
      expect(TripMath.past(all, now).map((Trip x) => x.id), <String>['d', 't']);
      expect(TripMath.pastDestinations(all, catalog: catalog),
          <String>['Bali', 'Istanbul', 'Bergen']);
    });
  });

  group('menu', () {
    test('"My trips" sits in Advanced features with a plane and "new"', () {
      final NavDestination d = AppNav.all
          .firstWhere((NavDestination x) => x.section == AppSection.trips);
      expect(d.group, NavGroup.advanced);
      expect(d.route, '/trips');
      expect(d.icon, Icons.flight_takeoff_outlined);
      expect(d.isNew, isTrue);
      // Hidden from the store build until it launches; shown in testing.
      expect(AppNav.isLaunched(d), isFalse);
      expect(AppEnv.smartTrip, isTrue); // tests run as a debug build
      expect(AppNav.destinations, contains(d));
    });
  });

  group('screens', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<ProviderContainer> pump(WidgetTester tester, Widget child,
        {Locale locale = const Locale('en'),
        bool dark = false,
        Map<String, Object> prefs = const <String, Object>{}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        destinationCatalogProvider.overrideWith((_) async => catalog),
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

    Map<String, Object> stored(List<Trip> trips) => <String, Object>{
          'sb_trips_guest':
              jsonEncode(trips.map((Trip t) => t.toJson()).toList()),
        };

    Future<List<Trip>> saved(ProviderContainer c) =>
        c.read(tripStoreProvider).all();

    testWidgets('a trip to a suggested place', (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester, const SingleChildScrollView(child: TripEditorSheet()));
      expect(find.text('Where to?'), findsOneWidget);
      expect(find.text('Show all (15)'), findsOneWidget);
      expect(find.text('Barcelona'), findsNothing);
      await tester.tap(find.text('Show all (15)'));
      await tester.pumpAndSettle();
      expect(find.text('Barcelona'), findsOneWidget);
      await tester.tap(find.text('Istanbul'));
      await tester.pumpAndSettle();
      // Picked, not chosen yet: the card shows the country and the source.
      expect(find.text('Türkiye · From the list'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirm destination'));
      await tester.tap(find.text('Confirm destination'));
      await tester.pumpAndSettle();
      expect(find.text('Destination chosen: Istanbul'), findsOneWidget);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final Trip t = (await saved(c)).single;
      expect(t.destination, 'Istanbul');
      expect(t.name, 'Trip to Istanbul');
      expect(t.plannedBudget, isNull);
    });

    testWidgets('a trip to any typed place', (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester, const SingleChildScrollView(child: TripEditorSheet()));
      await tester.enterText(find.byType(TextField).first, '  bergen   norway');
      await tester.pumpAndSettle();
      expect(find.text('Use: Bergen Norway'), findsOneWidget);
      await tester.tap(find.text('Use: Bergen Norway'));
      await tester.pumpAndSettle();
      expect(find.text('Typed in'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirm destination'));
      await tester.tap(find.text('Confirm destination'));
      await tester.pumpAndSettle();
      // The search field gives way to the chosen place: name, then budget.
      await tester.enterText(find.byType(TextField).at(0), 'Fjords');
      await tester.enterText(find.byType(TextField).last, '1200'); // budget
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final Trip t = (await saved(c)).single;
      expect(t.destination, 'Bergen Norway');
      expect(t.name, 'Fjords');
      expect(t.plannedBudget, const Money(120000, 'USD'));
    });

    testWidgets('no place, no save', (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester, const SingleChildScrollView(child: TripEditorSheet()));
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Choose where you are going.'), findsOneWidget);
      expect(await saved(c), isEmpty);
    });

    testWidgets('earlier places come first, in the app language',
        (WidgetTester tester) async {
      await pump(tester, const SingleChildScrollView(child: TripEditorSheet()),
          locale: const Locale('ar'),
          prefs: stored(<Trip>[
            trip('a', 'Istanbul', from: -30, to: -25),
            trip('b', 'Bergen', from: -60, to: -55),
          ]));
      expect(find.text('من رحلاتك'), findsOneWidget);
      // The past chips come before the popular ones.
      final double pastY = tester.getTopLeft(find.text('Bergen')).dy;
      final double popularY = tester.getTopLeft(find.text('وجهات مقترحة')).dy;
      expect(pastY, lessThan(popularY));
      // Istanbul shows once among the past places, named in Arabic.
      expect(find.text('إسطنبول'), findsNWidgets(2)); // past + popular
      // Typing finds the typed place again.
      await tester.enterText(find.byType(TextField).first, 'berg');
      await tester.pumpAndSettle();
      expect(find.text('Bergen'), findsOneWidget);
      expect(find.text('استخدم: Berg'), findsOneWidget);
    });

    testWidgets('a new expense is tagged with the trip under way',
        (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester,
          const TransactionEditorSheet(
            type: TransactionType.expense,
            prefill: TransactionDraft(amount: 42, category: 'المطاعم'),
          ),
          prefs: stored(<Trip>[trip('on', 'Rome', from: -1, to: 3)]));
      expect(find.text('Part of a trip (optional)'), findsOneWidget);
      expect(find.text('Trip on'), findsOneWidget);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final List<Transaction> txns =
          await c.read(financeRepositoryProvider).watchAll().first;
      expect(txns.single.tripId, 'on');
    });

    testWidgets('within a trip: its items first, saved under a category',
        (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester,
          const TransactionEditorSheet(
            type: TransactionType.expense,
            prefill: TransactionDraft(amount: 42),
          ),
          prefs: stored(<Trip>[trip('on', 'Rome', from: -1, to: 3)]));
      expect(find.text('Trip item'), findsOneWidget);
      await tester.tap(find.text('Flights'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final Transaction saved =
          (await c.read(financeRepositoryProvider).watchAll().first).single;
      expect(saved.category, 'السفر');
      expect(saved.tripId, 'on');
    });

    testWidgets('no trip: the usual categories only',
        (WidgetTester tester) async {
      await pump(
          tester, const TransactionEditorSheet(type: TransactionType.expense),
          prefs: stored(<Trip>[trip('old', 'Rome', from: -30, to: -25)]));
      expect(find.text('Trip item'), findsNothing);
    });

    testWidgets('income has no trip field', (WidgetTester tester) async {
      await pump(
          tester, const TransactionEditorSheet(type: TransactionType.income),
          prefs: stored(<Trip>[trip('on', 'Rome', from: -1, to: 3)]));
      expect(find.text('Part of a trip (optional)'), findsNothing);
    });

    for (final (Locale, TextDirection, String) v
        in const <(Locale, TextDirection, String)>[
      (Locale('en'), TextDirection.ltr, 'My trips'),
      (Locale('ar'), TextDirection.rtl, 'رحلاتي'),
      (Locale('ur'), TextDirection.rtl, 'میرے سفر'),
      (Locale('tr'), TextDirection.ltr, 'Seyahatlerim'),
    ]) {
      testWidgets('my trips in ${v.$1.languageCode}',
          (WidgetTester tester) async {
        await pump(tester, const TripsPage(),
            locale: v.$1,
            prefs: stored(<Trip>[
              trip('a', 'Istanbul',
                  from: -1, to: 3, budget: const Money(50000, 'USD')),
              trip('b', 'Bergen', from: -30, to: -25),
            ]));
        expect(find.text(v.$3), findsOneWidget);
        expect(Directionality.of(tester.element(find.text(v.$3))), v.$2);
        final String istanbul = catalog
            .byText('Istanbul')!
            .nameFor(AppLang.fromCode(v.$1.languageCode));
        expect(find.textContaining(istanbul), findsOneWidget);
        expect(find.textContaining('Bergen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no trips yet', (WidgetTester tester) async {
      await pump(tester, const TripsPage());
      expect(find.text('No trips yet'), findsOneWidget);
    });

    testWidgets('picking needs a confirmation; a past place says so',
        (WidgetTester tester) async {
      final ProviderContainer c = await pump(
          tester, const SingleChildScrollView(child: TripEditorSheet()),
          prefs: stored(<Trip>[trip('a', 'Bergen', from: -60, to: -55)]));
      await tester.tap(find.text('Bergen'));
      await tester.pumpAndSettle();
      expect(find.text('From your trips'), findsNWidgets(2)); // label + card
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Choose where you are going.'), findsOneWidget,
          reason: 'not confirmed yet');
      expect((await saved(c)).length, 1);
    });

    for (final bool dark in <bool>[false, true]) {
      testWidgets(
          'the picker in the ${dark ? 'dark' : 'light'} theme, '
          'right to left', (WidgetTester tester) async {
        await pump(
            tester, const SingleChildScrollView(child: TripEditorSheet()),
            locale: const Locale('ar'), dark: dark);
        await tester.tap(find.text('لندن'));
        await tester.pumpAndSettle();
        expect(find.text('بريطانيا · من القائمة'), findsOneWidget);
        expect(Directionality.of(tester.element(find.text('تأكيد الوجهة'))),
            TextDirection.rtl);
        await tester.ensureVisible(find.text('تأكيد الوجهة'));
        await tester.tap(find.text('تأكيد الوجهة'));
        await tester.pumpAndSettle();
        expect(find.text('تم اختيار الوجهة: لندن'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
