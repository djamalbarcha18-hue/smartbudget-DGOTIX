import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/storage/save_health.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/settings/presentation/settings_page.dart';
import 'package:smartbudget/features/shell/save_problem_banner.dart';
import 'package:smartbudget/features/sync/application/sync_controller.dart';
import 'package:smartbudget/features/transactions/data/fake_transaction_repository.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Device storage that can be made to refuse writes: by throwing (a full
/// browser storage) or by answering false (a write the phone didn't make).
class _Storage extends InMemorySharedPreferencesStore {
  _Storage() : super.empty();

  bool throws = false;
  bool refuses = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (throws) throw StateError('QuotaExceededError');
    if (refuses) return false;
    return super.setValue(valueType, key, value);
  }
}

class _FixedSync extends SyncController {
  _FixedSync(this.status);
  final SyncStatus status;
  @override
  SyncStatus build() => status;
}

class _Note {
  const _Note(this.id, this.text);
  final String id;
  final String text;
}

LocalListStore<_Note> _notes() => LocalListStore<_Note>(
      key: 'sb_notes_test',
      fromJson: (Map<String, dynamic> j) =>
          _Note(j['id'] as String, j['text'] as String),
      toJson: (_Note n) => <String, dynamic>{'id': n.id, 'text': n.text},
      idOf: (_Note n) => n.id,
    );

Transaction _txn(String id) => Transaction(
      id: id,
      date: DateTime(2026, 10, 20),
      type: TransactionType.expense,
      category: 'المطاعم',
      amount: const Money(4550, 'DZD'),
      description: 'Lunch $id',
      createdAt: DateTime(2026, 10, 20),
    );

Future<String?> _stored(String key) async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  await p.reload();
  return p.getString(key);
}

void main() {
  late _Storage storage;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    SharedPreferences.resetStatic();
    storage = _Storage();
    SharedPreferencesStorePlatform.instance = storage;
    SaveHealth.reset();
  });

  group('SaveHealth', () {
    test('a failed write shows until that same store is written', () async {
      int tries = 0;
      SaveHealth.failed('a', () async => tries++);
      SaveHealth.failed('b', () async => SaveHealth.saved('b'));
      expect(SaveHealth.failing.value, isTrue);
      SaveHealth.saved('other');
      expect(SaveHealth.failing.value, isTrue);
      expect(await SaveHealth.retryAll(), isFalse); // «a» still fails
      expect(tries, 1);
      SaveHealth.saved('a');
      expect(SaveHealth.failing.value, isFalse);
    });
  });

  group('a list on the device', () {
    test('full storage: nothing lost, the user is told, a retry stores it',
        () async {
      final LocalListStore<_Note> store = _notes();
      await store.upsert(const _Note('1', 'first'));
      expect(SaveHealth.failing.value, isFalse);

      storage.throws = true;
      await store.upsert(const _Note('2', 'second'));
      expect(SaveHealth.failing.value, isTrue);
      expect(store.current.map((_Note n) => n.id), <String>['1', '2']);
      expect(await _stored('sb_notes_test'), isNot(contains('second')));

      expect(await SaveHealth.retryAll(), isFalse); // still full
      expect(SaveHealth.failing.value, isTrue);

      storage.throws = false;
      expect(await SaveHealth.retryAll(), isTrue);
      expect(SaveHealth.failing.value, isFalse);
      final List<dynamic> saved =
          jsonDecode((await _stored('sb_notes_test'))!) as List<dynamic>;
      expect(saved.length, 2);
    });

    test('a write the device answers «no» to counts as failed', () async {
      final LocalListStore<_Note> store = _notes();
      storage.refuses = true;
      await store.upsert(const _Note('1', 'first'));
      expect(SaveHealth.failing.value, isTrue);
      storage.refuses = false;
      await store.upsert(const _Note('2', 'second')); // the next one works
      expect(SaveHealth.failing.value, isFalse);
      expect(await _stored('sb_notes_test'), contains('first'));
    });
  });

  group('transactions', () {
    test('a transaction added while storage is full is stored on retry',
        () async {
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: 'u1');
      await repo.add(_txn('a'));
      storage.throws = true;
      await repo.add(_txn('b'));
      expect(SaveHealth.failing.value, isTrue);
      expect(repo.current.length, 2);
      storage.throws = false;
      expect(await SaveHealth.retryAll(), isTrue);
      final List<dynamic> saved =
          jsonDecode((await _stored('sb_txns_u1'))!) as List<dynamic>;
      expect(
          saved.map((dynamic t) => t['id']), containsAll(<String>['a', 'b']));
    });
  });

  group('on screen', () {
    Widget app(Widget child) => MaterialApp(
          locale: const Locale('ar'),
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
          home: child,
        );

    testWidgets('the warning comes and goes with the failed writes',
        (WidgetTester tester) async {
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      final LocalListStore<_Note> store = _notes();
      await tester.pumpWidget(ProviderScope(
        child:
            app(const SaveProblemBanner(child: Scaffold(body: Text('page')))),
      ));
      expect(find.text(l.saveFailedTitle), findsNothing);

      storage.throws = true;
      await tester.runAsync(() => store.upsert(const _Note('1', 'x')));
      await tester.pump();
      expect(find.text(l.saveFailedTitle), findsOneWidget);
      expect(find.text(l.saveFailedWhy), findsOneWidget);
      expect(find.text(l.backupNow), findsOneWidget);
      expect(find.text('page'), findsOneWidget); // the page stays usable

      // Still full: the warning stays.
      await tester.tap(find.text(l.loadRetry));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text(l.saveFailedTitle), findsOneWidget);

      storage.throws = false;
      await tester.tap(find.text(l.loadRetry));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text(l.saveFailedTitle), findsNothing);
      expect(find.text(l.saveRetryDone), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // The settings page starts background timers: close it and let them
    // run out before the test ends.
    Future<void> close(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await tester.pump();
    }

    Future<ProviderContainer> settings(
        WidgetTester tester, SyncStatus sync) async {
      tester.view.physicalSize = const Size(2700, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        effectivePlanProvider.overrideWithValue(Plan.free),
        syncControllerProvider.overrideWith(() => _FixedSync(sync)),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: app(const Scaffold(body: SettingsPage())),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('settings say the data is on this phone only',
        (WidgetTester tester) async {
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      final ProviderContainer c =
          await settings(tester, const SyncStatus(SyncPhase.off));
      expect(find.text(l.dataWherePhone), findsOneWidget);
      expect(find.text(l.dataWhereCloud), findsNothing);
      await close(tester, c);
    });

    testWidgets('settings say the data is in the account while it syncs',
        (WidgetTester tester) async {
      final AppLocalizations l =
          await AppLocalizations.delegate.load(const Locale('ar'));
      final ProviderContainer c =
          await settings(tester, const SyncStatus(SyncPhase.idle));
      expect(find.text(l.dataWhereCloud), findsOneWidget);
      expect(find.text(l.dataWherePhone), findsNothing);
      await close(tester, c);
    });
  });
}
