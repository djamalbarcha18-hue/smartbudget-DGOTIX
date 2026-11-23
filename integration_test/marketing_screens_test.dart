// Marketing screenshots for the «شلة الغربة» ad series.
//
// Runs the real app (local demo backend, no Supabase, no real accounts) in
// Chrome at a phone size, fills it with the built-in sample data in each
// character's currency, and saves a screenshot of every page the ads use.
// Run by .github/workflows/marketing-screenshots.yml — never part of CI.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/app.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/features/dev/sample_data_controller.dart';
import 'package:smartbudget/features/quick_entry/presentation/quick_entry_sheet.dart';
import 'package:smartbudget/features/shell/app_shell.dart';
import 'package:smartbudget/main.dart' as app;

/// Each character of the series and the currency their screens use.
const Map<String, String> kCharacters = <String, String>{
  'mona': 'CAD',
  'saud': 'SAR',
  'yassine': 'DZD',
  'omar': 'MAD',
};

/// The pages the ads show, by route.
const List<String> kRoutes = <String>[
  '/dashboard',
  '/transactions',
  '/expenses',
  '/assistant',
  '/budget',
  '/goals',
  '/wallets',
  '/markets',
  '/metals',
  '/exchange-rates',
  '/zakat',
  '/sadaqah',
  '/seasons',
  '/reports',
  '/portfolio',
];

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, {int frames = 25}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    try {
      await binding.takeScreenshot(name);
    } catch (e) {
      debugPrint('screenshot $name failed: $e');
    }
  }

  testWidgets('marketing screenshots', (WidgetTester tester) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues(<String, Object>{
      // Signed in on the local demo backend (no real account).
      'sb_auth_uid': 'demo-shella',
      'sb_auth_email': 'demo@dgotix.com',
      'sb_auth_name': 'SmartBudget',
      'sb_locale': 'ar',
      'sb_theme_mode': 'light',
      'sb_islamic_features': true,
      // No first-run cards or hints over the pages.
      'sb_onboarding': '{"d":true,"s":true,"g":true,"f":$now}',
      'sb_sadaqah_intro_done': true,
      'sb_sadaqah_ramadan_seen': true,
      'sb_menu_hint_tapped': true,
      'voice_notice_seen': true,
      'sb_offers_notice_seen': true,
      'sb_install_dismissed_at': now,
    });

    app.main();
    await settle(tester, frames: 60);

    final ProviderContainer c =
        ProviderScope.containerOf(tester.element(find.byType(SmartBudgetApp)));
    await c.read(themeModeProvider.notifier).set(ThemeMode.light);
    await c.read(localeProvider.notifier).set(const Locale('ar'));
    await settle(tester);

    GoRouter router() => GoRouter.of(tester.element(find.byType(AppShell)));

    for (final MapEntry<String, String> who in kCharacters.entries) {
      await c.read(sampleDataLoaderProvider).clear();
      await c.read(baseCurrencyProvider.notifier).set(who.value);
      await settle(tester);
      await c.read(sampleDataLoaderProvider).load();
      await settle(tester, frames: 40);

      for (final String route in kRoutes) {
        router().go(route);
        await shot(
            tester, '${who.key}_${route.substring(1).replaceAll('/', '_')}');
      }

      // The quick entry sheet: empty, then with a typed expense.
      router().go('/dashboard');
      await settle(tester);
      QuickEntrySheet.show(tester.element(find.byType(AppShell)));
      await shot(tester, '${who.key}_quick_entry');
      final Finder field = find.byType(TextField);
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field.first, 'قهوة 5');
        await shot(tester, '${who.key}_quick_entry_typed');
      }
      final Finder sheet = find.byType(QuickEntrySheet);
      if (sheet.evaluate().isNotEmpty) {
        Navigator.of(tester.element(sheet)).maybePop();
      }
      await settle(tester);
    }
  });
}
