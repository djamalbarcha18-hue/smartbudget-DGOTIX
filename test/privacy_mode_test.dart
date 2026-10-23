import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/privacy/application/privacy_controller.dart';
import 'package:smartbudget/features/privacy/presentation/money_privacy_host.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('PrivacyState', () {
    test('masked by the choice, or while an entry is open', () {
      expect(const PrivacyState().masked, isFalse);
      expect(const PrivacyState(hidden: true).masked, isTrue);
      expect(const PrivacyState(openEntries: 1).masked, isTrue);
      expect(
          const PrivacyState(openEntries: 1, hideWhileEntering: false).masked,
          isFalse);
    });

    test('the choice is kept; open entries never go below zero', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final PrivacyController ctrl = c.read(privacyProvider.notifier);
      await ctrl.toggle();
      expect(c.read(privacyProvider).hidden, isTrue);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sb_privacy_hidden'), isTrue);

      ctrl.endEntry();
      expect(c.read(privacyProvider).openEntries, 0);
    });
  });

  Widget host(ProviderContainer c, Locale locale) => UncontrolledProviderScope(
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
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
            DsColors.light,
            DsGlass.light
          ]),
          builder: (BuildContext context, Widget? child) =>
              MoneyPrivacyHost(child: child!),
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                KpiCard(
                  label: 'Income',
                  value: r'$1,250.00',
                  delta: KpiDelta(label: '+12%', trend: KpiTrend.up),
                ),
                KpiCard(label: 'Expenses', value: r'$480.00'),
                KpiCard(label: 'Empty', value: null),
              ],
            ),
          ),
        ),
      );

  for (final Locale locale in const <Locale>[Locale('en'), Locale('ar')]) {
    testWidgets('the eye hides and shows every figure (${locale.languageCode})',
        (WidgetTester tester) async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(c, locale));
      await tester.pumpAndSettle();

      expect(find.text(r'$1,250.00'), findsOneWidget);
      expect(find.text('+12%'), findsOneWidget);
      // No eye on a card with nothing to hide.
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text(r'$1,250.00'), findsNothing);
      expect(find.text(r'$480.00'), findsNothing);
      expect(find.text('+12%'), findsNothing);
      expect(find.text(MoneyPrivacy.mask), findsNWidgets(2));
      expect(find.text('—'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text(r'$480.00'), findsOneWidget);
    });
  }

  testWidgets('press and hold peeks at one hidden figure',
      (WidgetTester tester) async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(privacyProvider.notifier).setHidden(true);
    await tester.pumpWidget(host(c, const Locale('en')));
    await tester.pumpAndSettle();

    final TestGesture g = await tester
        .startGesture(tester.getCenter(find.text(MoneyPrivacy.mask).first));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text(r'$1,250.00'), findsOneWidget);
    expect(find.text(r'$480.00'), findsNothing);

    await g.up();
    await tester.pumpAndSettle();
    expect(find.text(r'$1,250.00'), findsNothing);
  });

  testWidgets('figures hide while an entry sheet is open',
      (WidgetTester tester) async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c, const Locale('en')));
    await tester.pumpAndSettle();

    final BuildContext ctx = tester.element(find.byType(Scaffold));
    PrivacyController.whileEntering(
        ctx,
        () => showModalBottomSheet<void>(
            context: ctx, builder: (_) => const Text('entry')));
    await tester.pumpAndSettle();
    expect(find.text(r'$1,250.00'), findsNothing);

    Navigator.of(tester.element(find.text('entry'))).pop();
    await tester.pumpAndSettle();
    expect(find.text(r'$1,250.00'), findsOneWidget);
  });
}
