import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/sync/application/data_loading.dart';
import 'package:smartbudget/features/sync/application/sync_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Sync status set by the test.
class _FixedSync extends SyncController {
  _FixedSync(this.status);
  final SyncStatus status;
  @override
  SyncStatus build() => status;
}

Widget _app(Widget child,
    {DsColors colors = DsColors.light,
    DsGlass glass = DsGlass.light,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    bool reduceMotion = false}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...fallbackLocalizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
        brightness: brightness,
        extensions: <ThemeExtension<dynamic>>[colors, glass]),
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Transaction _txn(String id) => Transaction(
      id: id,
      date: DateTime(2026, 10, 20),
      type: TransactionType.expense,
      category: 'المطاعم',
      amount: const Money(4550, 'SAR'),
      description: 'Lunch $id',
      createdAt: DateTime(2026, 10, 20),
    );

class _BuildCounter extends StatelessWidget {
  const _BuildCounter(this.onBuild);
  final VoidCallback onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild();
    return const DsBone(width: 100);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('when to wait', () {
    test('only while nothing is on the device and data is on its way', () {
      const AsyncValue<List<int>> reading = AsyncLoading<List<int>>();
      const AsyncValue<List<int>> empty = AsyncData<List<int>>(<int>[]);
      const AsyncValue<List<int>> some = AsyncData<List<int>>(<int>[1]);
      expect(awaitingData(reading, cloudPending: false), isTrue);
      expect(awaitingData(empty, cloudPending: false), isFalse);
      expect(awaitingData(empty, cloudPending: true), isTrue);
      // What the device has shows at once, cloud or not.
      expect(awaitingData(some, cloudPending: true), isFalse);
    });

    test('the cloud copy is awaited only until this device first gets it', () {
      bool pending(SyncStatus s) {
        final ProviderContainer c = ProviderContainer(overrides: <Override>[
          syncControllerProvider.overrideWith(() => _FixedSync(s)),
        ]);
        addTearDown(c.dispose);
        return c.read(firstCloudCopyPendingProvider);
      }

      expect(pending(const SyncStatus(SyncPhase.syncing)), isTrue);
      expect(pending(const SyncStatus(SyncPhase.idle)), isTrue);
      expect(pending(SyncStatus(SyncPhase.syncing, lastSyncedAt: DateTime(2026))),
          isFalse);
      expect(pending(const SyncStatus(SyncPhase.off)), isFalse);
      expect(pending(const SyncStatus(SyncPhase.offline)), isFalse);
      expect(pending(const SyncStatus(SyncPhase.error)), isFalse);
    });
  });

  group('the skeleton', () {
    testWidgets('a quick load never flashes it; a slow one says so',
        (WidgetTester tester) async {
      int retries = 0;
      await tester.pumpWidget(_app(DsSkeleton(
        semanticsLabel: 'Loading',
        slowMessage: 'Taking longer',
        retryLabel: 'Try again',
        onRetry: () => retries++,
        child: const DsSkeletonList(count: 2),
      )));
      AnimatedOpacity fade() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(fade().opacity, 0); // hidden, but holding its place
      expect(tester.getSize(find.byType(DsSkeletonList)).height, 124);
      await tester.pump(const Duration(milliseconds: 200));
      expect(fade().opacity, 1);
      expect(find.text('Taking longer'), findsNothing);
      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Taking longer'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a bone with no width fills the card (the progress bar)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const SizedBox(
          width: 300, child: DsSkeletonCard(lines: 0, progress: true))));
      final Size bar = tester.getSize(find.byType(DsBone).last);
      expect(bar.height, 8);
      expect(bar.width, greaterThan(200));
    });

    testWidgets('screen readers hear «loading» once, not the shapes',
        (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(_app(const DsSkeleton(
          semanticsLabel: 'Loading', child: DsSkeletonCards(count: 2))));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      h.dispose();
    });

    testWidgets('the sweep repaints; it never rebuilds the shapes',
        (WidgetTester tester) async {
      int builds = 0;
      await tester.pumpWidget(_app(DsShimmerScope(
          child: _BuildCounter(() => builds++))));
      final int first = builds;
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(builds, first);
      expect(DsShimmerScope.of(tester.element(find.byType(DsBone))), isNotNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the sweep moves at most 30 times a second',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _app(const DsShimmerScope(child: DsBone(width: 80))));
      int moves = 0;
      DsShimmerScope.of(tester.element(find.byType(DsBone)))!
          .addListener(() => moves++);
      for (int i = 0; i < 125; i++) {
        await tester.pump(const Duration(milliseconds: 8)); // a 120 Hz screen
      }
      expect(moves, inInclusiveRange(25, DsShimmerScope.fps + 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a slow wait stops the sweep', (WidgetTester tester) async {
      await tester.pumpWidget(_app(const DsSkeleton(
          semanticsLabel: 'Loading',
          slowMessage: 'Taking longer',
          child: DsBone(width: 80))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(DsShimmerScope.of(tester.element(find.byType(DsBone))), isNotNull);
      await tester.pump(const Duration(seconds: 12));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Taking longer'), findsOneWidget);
      expect(DsShimmerScope.of(tester.element(find.byType(DsBone))), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion: the bones stay still',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(
          const DsShimmerScope(child: DsBone(width: 80)),
          reduceMotion: true));
      expect(DsShimmerScope.of(tester.element(find.byType(DsBone))), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('every theme, light and dark, both directions',
        (WidgetTester tester) async {
      final Map<String, DsSkeletonColors> seen = <String, DsSkeletonColors>{};
      for (final (String name, DsColors colors, DsGlass glass, Brightness b)
          in <(String, DsColors, DsGlass, Brightness)>[
        ('light', DsColors.light, DsGlass.light, Brightness.light),
        ('dark', DsColors.dark, DsGlass.dark, Brightness.dark),
        ('beige', DsColors.beige, DsGlass.beige, Brightness.light),
        ('sage', DsColors.sage, DsGlass.light, Brightness.light),
        ('pomegranate', DsColors.pomegranate, DsGlass.light, Brightness.light),
        ('black', DsColors.black, DsGlass.dark, Brightness.dark),
      ]) {
        for (final Locale locale in const <Locale>[Locale('ar'), Locale('en')]) {
          await tester.pumpWidget(_app(
            const DsSkeleton(
              semanticsLabel: 'Loading',
              delay: Duration.zero,
              child: Column(children: <Widget>[
                DsSkeletonCards(count: 1, progress: true),
                DsSkeletonList(count: 2, framed: true),
                DsSkeletonChart(height: 200),
              ]),
            ),
            colors: colors,
            glass: glass,
            brightness: b,
            locale: locale,
          ));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: '$name $locale');
          seen[name] = DsSkeletonColors.of(tester.element(find.byType(DsBone).first));
        }
      }
      // Bones follow each theme's own colours.
      expect(seen['light']!.bone, isNot(seen['dark']!.bone));
      expect(seen['beige']!.bone, isNot(seen['light']!.bone));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the transactions list', () {
    Future<StreamController<List<Transaction>>> pump(WidgetTester tester,
        {SyncStatus sync = const SyncStatus(SyncPhase.off)}) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(1170, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final StreamController<List<Transaction>> data =
          StreamController<List<Transaction>>();
      addTearDown(data.close);
      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          transactionsProvider.overrideWith((Ref ref) => data.stream),
          syncControllerProvider.overrideWith(() => _FixedSync(sync)),
        ],
        child: _app(const TransactionsListView()),
      ));
      return data;
    }

    testWidgets('reading the device: skeleton, then the rows',
        (WidgetTester tester) async {
      final StreamController<List<Transaction>> data = await pump(tester);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(DsSkeletonList), findsOneWidget);
      data.add(<Transaction>[_txn('a'), _txn('b')]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DsSkeletonList), findsNothing);
      expect(find.text('Lunch a'), findsOneWidget);
    });

    testWidgets('nothing at all: the empty state, no skeleton',
        (WidgetTester tester) async {
      final StreamController<List<Transaction>> data = await pump(tester);
      data.add(const <Transaction>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DsSkeletonList), findsNothing);
      expect(find.byType(DsEmpty), findsOneWidget);
    });

    testWidgets('a new device: skeleton until the cloud copy arrives',
        (WidgetTester tester) async {
      final StreamController<List<Transaction>> data =
          await pump(tester, sync: const SyncStatus(SyncPhase.syncing));
      data.add(const <Transaction>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DsSkeletonList), findsOneWidget);
      expect(find.byType(DsEmpty), findsNothing);
    });

    testWidgets('rows on the device show at once, even while syncing',
        (WidgetTester tester) async {
      final StreamController<List<Transaction>> data =
          await pump(tester, sync: const SyncStatus(SyncPhase.syncing));
      data.add(<Transaction>[_txn('a')]);
      await tester.pump();
      expect(find.byType(DsSkeletonList), findsNothing);
      expect(find.text('Lunch a'), findsOneWidget);
    });

    testWidgets('a failed read: a plain message and «try again»',
        (WidgetTester tester) async {
      final StreamController<List<Transaction>> data = await pump(tester);
      data.addError(StateError('disk'));
      await tester.pump();
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.loadFailed), findsOneWidget);
      expect(find.text(l.loadRetry), findsOneWidget);
      expect(find.textContaining('disk'), findsNothing);
    });
  });
}
