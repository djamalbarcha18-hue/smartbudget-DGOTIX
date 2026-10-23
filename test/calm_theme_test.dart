import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/settings/presentation/settings_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Relative luminance contrast between two colours (WCAG).
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the calm palette', () {
    test('a light theme with its own colours and surfaces', () {
      final ThemeData t = DsTheme.calm();
      expect(t.brightness, Brightness.light);
      expect(t.extension<DsColors>(), DsColors.calm);
      expect(t.extension<DsGlass>(), DsGlass.calm);
      expect(t.scaffoldBackgroundColor, DsColors.calm.bgPage);
    });

    test('softer than the light theme, still easy to read', () {
      const DsColors c = DsColors.calm;
      // Text stays readable (WCAG AA: 4.5 for body text).
      expect(contrast(c.textPrimary, c.surface), greaterThan(7));
      expect(contrast(c.textMuted, c.surface), greaterThan(4.5));
      expect(contrast(c.textPrimary, c.bgPage), greaterThan(7));
      // The soft pomegranate of expenses still reads on every surface.
      expect(c.expense, const Color(0xFFB5475A));
      expect(contrast(c.expense, c.surface), greaterThan(4.5));
      expect(contrast(c.expense, c.bgPage), greaterThan(4.5));
      expect(contrast(c.income, c.surface), greaterThan(4.5));
      // Less glare: less black-on-white than the standard light theme.
      expect(
          contrast(c.textPrimary, c.bgPage),
          lessThan(
              contrast(DsColors.light.textPrimary, DsColors.light.bgPage)));
    });

    test('a Pro feature, prepared for the paid plan', () {
      expect(FeatureCatalog.minTierFor(Feature.calmTheme), Plan.pro);
      expect(FeatureGate.evaluate(Feature.calmTheme, plan: Plan.free).allowed,
          isFalse);
      expect(FeatureGate.evaluate(Feature.calmTheme, plan: Plan.pro).allowed,
          isTrue);
    });
  });

  group('settings', () {
    // The settings page starts background timers (sync…): close it and let
    // them run out before the test ends.
    Future<void> close(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose(); // stops the providers' periodic timers
      await tester.pump();
    }

    Future<ProviderContainer> pump(WidgetTester tester, Plan plan,
        {Map<String, Object> prefs = const <String, Object>{}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      // Wide: the test font is much wider than the real ones.
      tester.view.physicalSize = const Size(2700, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        effectivePlanProvider.overrideWithValue(plan),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
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
          home: const Scaffold(body: SettingsPage()),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('Pro: turning it on also shows the light theme',
        (WidgetTester tester) async {
      expect(AppEnv.calmTheme, isTrue); // debug build: shown
      final ProviderContainer c = await pump(tester, Plan.pro,
          prefs: <String, Object>{'flutter.sb_theme_mode': 'dark'});
      expect(c.read(themeModeProvider), ThemeMode.dark);
      await tester.tap(find.text('مظهر هادئ (تجريبي)'));
      await tester.pumpAndSettle();
      expect(c.read(calmThemeProvider), isTrue);
      expect(c.read(themeModeProvider), ThemeMode.light);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sb_theme_calm'), isTrue);
      await close(tester, c);
    });

    testWidgets('free plan: the upgrade sheet, nothing changes',
        (WidgetTester tester) async {
      final ProviderContainer c = await pump(tester, Plan.free);
      await tester.tap(find.text('مظهر هادئ (تجريبي)'));
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeSheet), findsOneWidget);
      expect(c.read(calmThemeProvider), isFalse);
      await close(tester, c);
    });
  });
}
