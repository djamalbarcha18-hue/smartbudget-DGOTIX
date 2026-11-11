import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/application/daret_import.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/daret/domain/daret_link.dart';
import 'package:smartbudget/features/daret/presentation/daret_import_sheet.dart';
import 'package:smartbudget/features/daret/presentation/daret_share_sheet.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

final Daret _daret = Daret(
  id: 'daret-1',
  name: 'Family circle',
  contribution: const Money(500000, 'DZD'),
  frequency: DaretFrequency.monthly,
  start: DateTime(2026, 12, 1),
  members: const <String>['Ahmed', 'Sara', 'Leila', 'Omar'],
  meIndex: 0,
  createdAt: DateTime(2026, 11, 1),
  paidRounds: const <int>{0},
);

String get _payload => DaretLink.encode(_daret);

Widget _app(Widget home, {List<Override> overrides = const <Override>[]}) =>
    ProviderScope(
      overrides: <Override>[
        referralCodeProvider.overrideWith((Ref ref) async => 'AB23CD45'),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// The darets saved on this (mock) device.
Future<List<Daret>> _saved(WidgetTester tester) async {
  final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false);
  return c.read(daretStoreProvider).all();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the waiting daret', () {
    test('a link with a daret is remembered, read back and cleared', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await DaretPending.remember(
          Uri.parse('https://x.test/?daret=$_payload&ref=AB23CD45'));
      expect((await DaretPending.read())!.name, 'Family circle');
      await DaretPending.clear();
      expect(await DaretPending.read(), isNull);
    });

    test('a link without one, or with junk, leaves nothing waiting', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await DaretPending.remember(Uri.parse('https://x.test/'));
      await DaretPending.remember(Uri.parse('https://x.test/?daret=junk'));
      expect(await DaretPending.read(), isNull);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString(DaretPending.prefKey), isNull);
    });

    test('junk put in storage by hand is never offered', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{DaretPending.prefKey: 'not a daret'});
      expect(await DaretPending.read(), isNull);
    });
  });

  group('sharing', () {
    testWidgets('the sheet shows every round and copies a link that works',
        (WidgetTester tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<dynamic, dynamic>)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(
          _app(Scaffold(body: DaretShareSheet(daret: _daret))));
      await tester.pump();
      for (final String m in _daret.members) {
        expect(find.textContaining(m), findsOneWidget);
      }
      expect(find.textContaining('Nothing is stored on our servers'),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('daret-copy-link')));
      await tester.pump();
      expect(copied, isNotNull);
      final Uri link = Uri.parse(copied!);
      // The link is the schedule, plus the sharer's invite code.
      final SharedDaret back = DaretLink.decode(DaretLink.payloadIn(link))!;
      expect(back.sameScheduleAs(_daret), isTrue);
      expect(link.queryParameters['ref'], 'AB23CD45');
    });
  });

  group('receiving', () {
    Future<void> open(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(Scaffold(
          body: DaretImportSheet(shared: DaretLink.decode(_payload)!))));
      await tester.pump();
    }

    testWidgets('nothing is added until the member says who they are',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{DaretPending.prefKey: _payload});
      await open(tester);
      expect(find.text('Which one are you?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('daret-import-add')));
      await tester.pump();
      expect(await tester.runAsync(() => _saved(tester)), isEmpty);
    });

    testWidgets('picking a name adds their own clean copy',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{DaretPending.prefKey: _payload});
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('daret-member-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('daret-import-add')));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      final List<Daret> saved = (await tester.runAsync(() => _saved(tester)))!;
      expect(saved, hasLength(1));
      expect(saved.single.name, 'Family circle');
      expect(saved.single.meIndex, 2);
      // Their own tracking starts empty, whatever the sharer had ticked.
      expect(saved.single.paidRounds, isEmpty);
      expect(saved.single.id, isNot('daret-1'));
      // Offered once: nothing waits any more.
      expect(await tester.runAsync(DaretPending.read), isNull);
      expect(find.textContaining('Your turn:'), findsOneWidget);
    });

    testWidgets('"Not now" adds nothing and does not ask again',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{DaretPending.prefKey: _payload});
      await open(tester);
      await tester
          .tap(find.byKey(const ValueKey<String>('daret-import-skip')));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(await tester.runAsync(() => _saved(tester)), isEmpty);
      expect(await tester.runAsync(DaretPending.read), isNull);
    });
  });
}
