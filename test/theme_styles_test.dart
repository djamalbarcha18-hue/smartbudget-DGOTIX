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
import 'package:smartbudget/features/share/presentation/share_card_skin.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Relative luminance contrast between two colours (WCAG).
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Pro theme palettes', () {
    for (final (String, ThemeData Function(), DsColors, DsGlass) v
        in <(String, ThemeData Function(), DsColors, DsGlass)>[
      ('beige', () => DsTheme.beige(), DsColors.beige, DsGlass.beige),
      ('sage', () => DsTheme.sage(), DsColors.sage, DsGlass.sage),
      (
        'pomegranate',
        () => DsTheme.pomegranate(),
        DsColors.pomegranate,
        DsGlass.pomegranate
      ),
    ]) {
      test('${v.$1}: a light theme with its own colours, easy to read', () {
        final ThemeData t = v.$2();
        final DsColors c = v.$3;
        expect(t.brightness, Brightness.light);
        expect(t.extension<DsColors>(), c);
        expect(t.extension<DsGlass>(), v.$4);
        expect(t.scaffoldBackgroundColor, c.bgPage);
        // Readable text and figures (WCAG AA 4.5 for body text).
        for (final Color fg in <Color>[
          c.textPrimary,
          c.textMuted,
          c.income,
          c.expense,
          c.brand
        ]) {
          expect(contrast(fg, c.surface), greaterThan(4.5), reason: '$fg');
          expect(contrast(fg, c.bgPage), greaterThan(4.5), reason: '$fg');
        }
        // Less glare than black on the standard light background.
        expect(
            contrast(c.textPrimary, c.bgPage),
            lessThan(
                contrast(DsColors.light.textPrimary, DsColors.light.bgPage)));
        // Expenses in a pomegranate red.
        if (c != DsColors.pomegranate) {
          expect(c.expense, const Color(0xFFB5475A));
        }
      });
    }

    test('black: a dark theme with a gold accent, easy to read', () {
      final ThemeData t = DsTheme.black();
      const DsColors c = DsColors.black;
      expect(t.brightness, Brightness.dark);
      expect(t.extension<DsColors>(), c);
      expect(t.extension<DsGlass>(), DsGlass.black);
      expect(t.scaffoldBackgroundColor, c.bgPage);
      for (final Color fg in <Color>[
        c.textPrimary,
        c.textMuted,
        c.income,
        c.expense,
        c.brand
      ]) {
        expect(contrast(fg, c.surface), greaterThan(4.5), reason: '$fg');
        expect(contrast(fg, c.bgPage), greaterThan(4.5), reason: '$fg');
      }
      // Dark text on the gold buttons.
      expect(contrast(c.onBrand, c.brand), greaterThan(4.5));
    });

    test('Pro themes are a Pro feature', () {
      expect(FeatureCatalog.minTierFor(Feature.proThemes), Plan.pro);
      expect(FeatureGate.evaluate(Feature.proThemes, plan: Plan.free).allowed,
          isFalse);
      expect(FeatureGate.evaluate(Feature.proThemes, plan: Plan.pro).allowed,
          isTrue);
    });

    test('an earlier "beige on" setting is kept', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'flutter.sb_theme_calm': true});
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(themeStyleProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(themeStyleProvider), AppThemeStyle.beige);
    });
  });

  group('share cards in the Pro theme', () {
    test('every Pro theme has a card skin, white text easy to read', () {
      expect(ShareCardSkin.ofStyle(AppThemeStyle.classic), isNull);
      for (final AppThemeStyle style in AppThemeStyle.values) {
        if (style == AppThemeStyle.classic) continue;
        final ShareCardSkin skin = ShareCardSkin.ofStyle(style)!;
        for (final Color bg in skin.gradient) {
          expect(contrast(Colors.white, bg), greaterThan(4.5),
              reason: '$style $bg');
          expect(contrast(skin.accent, bg), greaterThan(4.5),
              reason: '$style accent on $bg');
        }
      }
    });

    Future<ProviderContainer> container(Plan plan, String style) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'flutter.sb_theme_style': style});
      final ProviderContainer c = ProviderContainer(overrides: <Override>[
        effectivePlanProvider.overrideWithValue(plan),
      ]);
      addTearDown(c.dispose);
      c.read(themeStyleProvider);
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    test('Pro with Black Gold: the card wears it, unless switched off',
        () async {
      final ProviderContainer c = await container(Plan.pro, 'black');
      expect(c.read(shareCardSkinProvider), ShareCardSkin.blackGold);
      c.read(shareCardUseThemeProvider.notifier).state = false;
      expect(c.read(shareCardSkinProvider), isNull);
    });

    test('free plan or Classic: the DGOTIX colours', () async {
      expect((await container(Plan.free, 'black')).read(shareCardSkinProvider),
          isNull);
      expect((await container(Plan.pro, 'classic')).read(shareCardSkinProvider),
          isNull);
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

    testWidgets('Pro: beige then sage from the picker, from dark to light',
        (WidgetTester tester) async {
      expect(AppEnv.proThemes, isTrue); // debug build: shown
      final ProviderContainer c = await pump(tester, Plan.pro,
          prefs: <String, Object>{'flutter.sb_theme_mode': 'dark'});
      expect(c.read(themeModeProvider), ThemeMode.dark);
      await tester.tap(find.text('بيج'));
      await tester.pumpAndSettle();
      expect(c.read(themeStyleProvider), AppThemeStyle.beige);
      expect(c.read(themeModeProvider), ThemeMode.light);
      await tester.tap(find.text('مريمية'));
      await tester.pumpAndSettle();
      expect(c.read(themeStyleProvider), AppThemeStyle.sage);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sb_theme_style'), 'sage');
      // Black switches to the dark mode, Pomegranate back to light.
      await tester.tap(find.text('أسود ذهبي'));
      await tester.pumpAndSettle();
      expect(c.read(themeStyleProvider), AppThemeStyle.black);
      expect(c.read(themeModeProvider), ThemeMode.dark);
      await tester.tap(find.text('رماني'));
      await tester.pumpAndSettle();
      expect(c.read(themeStyleProvider), AppThemeStyle.pomegranate);
      expect(c.read(themeModeProvider), ThemeMode.light);
      // Back to Classic.
      await tester.tap(find.text('كلاسيكي'));
      await tester.pumpAndSettle();
      expect(c.read(themeStyleProvider), AppThemeStyle.classic);
      await close(tester, c);
    });

    testWidgets('free plan: a Pro theme opens the upgrade sheet',
        (WidgetTester tester) async {
      final ProviderContainer c = await pump(tester, Plan.free);
      await tester.tap(find.text('بيج'));
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeSheet), findsOneWidget);
      expect(c.read(themeStyleProvider), AppThemeStyle.classic);
      await close(tester, c);
    });
  });
}
