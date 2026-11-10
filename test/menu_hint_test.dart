import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/shell/app_top_bar.dart';
import 'package:smartbudget/features/shell/menu_hint.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<ProviderContainer> _pump(WidgetTester tester,
    {Map<String, Object> prefs = const <String, Object>{},
    VoidCallback? onMenu}) async {
  SharedPreferences.setMockInitialValues(prefs);
  MenuHint.resetForTest();
  tester.view.physicalSize = const Size(1170, 2400); // 390 wide: a phone
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ProviderContainer c = ProviderContainer();
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      home: Scaffold(body: AppTopBar(onOpenMenu: onMenu)),
    ),
  ));
  // Let the stored state load, then let the nudge run its course.
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  return c;
}

/// Takes the screen and the container (and its background timers) away.
Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
  await tester.pump(const Duration(minutes: 1));
}

Finder get _menuTip => find.ancestor(
    of: find.byIcon(Icons.keyboard_arrow_down_rounded),
    matching: find.byType(Tooltip));

String _tipText(WidgetTester t) => t.widget<Tooltip>(_menuTip).message!;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the policy: until the menu is opened, for a few launches', () {
    expect(MenuHint.shouldShow(tapped: false, launches: 1), isTrue);
    expect(MenuHint.shouldShow(tapped: false, launches: MenuHint.maxLaunches),
        isTrue);
    expect(
        MenuHint.shouldShow(
            tapped: false, launches: MenuHint.maxLaunches + 1),
        isFalse);
    expect(MenuHint.shouldShow(tapped: true, launches: 1), isFalse);
  });

  testWidgets('a new person is told what the logo is, with a chevron under it',
      (WidgetTester tester) async {
    final ProviderContainer c = await _pump(tester);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(_tipText(tester), 'Tap the logo to open the menu');
    await _end(tester, c);
  });

  testWidgets('the first tap opens the menu and ends the hint for good',
      (WidgetTester tester) async {
    int opened = 0;
    final ProviderContainer c = await _pump(tester, onMenu: () => opened++);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
    expect(_tipText(tester), 'Open navigation menu');
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getBool('sb_menu_hint_tapped'), isTrue);
    await _end(tester, c);
    // The next launch: no hint any more.
    final ProviderContainer c2 = await _pump(tester,
        prefs: <String, Object>{'sb_menu_hint_tapped': true});
    expect(_tipText(tester), 'Open navigation menu');
    await _end(tester, c2);
  });

  testWidgets('after a handful of launches it stops by itself',
      (WidgetTester tester) async {
    final ProviderContainer c = await _pump(tester, prefs: <String, Object>{
      'sb_menu_hint_launches': MenuHint.maxLaunches,
    });
    expect(_tipText(tester), 'Open navigation menu');
    await _end(tester, c);
  });
}
