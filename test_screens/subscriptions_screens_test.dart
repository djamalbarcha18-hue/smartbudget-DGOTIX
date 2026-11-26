// ignore_for_file: invalid_use_of_visible_for_testing_member
// Screenshots of the subscription screens, for review before "publish".
// Not part of the normal test run: the Screenshots workflow runs
// `flutter test test_screens --update-goldens` and uploads the PNGs.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/recurring/presentation/recurring_page.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class _Dzd extends BaseCurrencyController {
  @override
  String build() => 'DZD';
}

/// Every font the app declares (FontManifest), so text and icons render.
Future<void> _loadFonts() async {
  final List<dynamic> manifest = json.decode(
      await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final dynamic f in manifest) {
    final FontLoader loader = FontLoader(f['family'] as String);
    for (final dynamic a in f['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(a['asset'] as String));
    }
    await loader.load();
  }
}

DateTime _inDays(int n) {
  final DateTime t = AppClock.now();
  return DateTime(t.year, t.month, t.day + n);
}

Future<ProviderContainer> _withSamples() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    effectivePlanProvider.overrideWithValue(Plan.free),
    baseCurrencyProvider.overrideWith(_Dzd.new),
  ]);
  final SubscriptionActions a = c.read(subscriptionActionsProvider);
  final DateTime now = AppClock.now();
  Subscription sub(String id, String name,
          {String? card, bool trial = false, String? catalog}) =>
      Subscription(
        id: id,
        ruleId: id,
        kind: SubscriptionKind.digital,
        provider: name,
        catalogId: catalog,
        cardName: card,
        trialEndsAt: trial ? _inDays(5) : null,
        status: trial ? SubscriptionStatus.trial : SubscriptionStatus.active,
        createdAt: now,
        updatedAt: now,
      );
  await a.save(sub('sub-1', 'Netflix', card: 'Edahabia', catalog: 'netflix'),
      amount: const Money(1599, 'USD'),
      frequency: RecurrenceFrequency.monthly,
      nextCharge: _inDays(3));
  await a.save(sub('sub-2', 'Spotify', card: 'RedotPay', trial: true),
      amount: const Money(999, 'USD'),
      frequency: RecurrenceFrequency.monthly,
      nextCharge: _inDays(5));
  await a.save(sub('sub-3', 'Djezzy', card: 'CIB'),
      amount: const Money(200000, 'DZD'),
      frequency: RecurrenceFrequency.monthly,
      nextCharge: _inDays(12));
  await a.save(sub('sub-4', 'Claude Pro', card: 'PayPal'),
      amount: const Money(20000, 'USD'),
      frequency: RecurrenceFrequency.yearly,
      nextCharge: _inDays(40));
  // Loaded and kept listened to, as on a running app, so the screens show
  // the data (a test's fake clock can't finish the first read itself).
  c.listen(subscriptionsProvider, (_, __) {});
  c.listen(recurringRulesProvider, (_, __) {});
  await c.read(subscriptionsProvider.future);
  await c.read(recurringRulesProvider.future);
  return c;
}

Widget _app(ProviderContainer c, Locale locale, Widget home) =>
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _theme(locale),
        home: home,
      ),
    );

ThemeData _theme(Locale locale) {
  final ThemeData t = DsTheme.dark(
      lang: locale.languageCode == 'ar' ? AppLang.ar : AppLang.fr);
  // The bundled Tajawal under its plain family name (google_fonts can't load
  // in a test).
  return t.copyWith(
    textTheme: t.textTheme
        .apply(fontFamily: 'SbTajawal', fontFamilyFallback: <String>['SbInter']),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    LatinDigits.enforce(); // as the app does at start (main.dart)
    await _loadFonts();
  });

  for (final Locale locale in const <Locale>[Locale('ar'), Locale('fr')]) {
    final String lang = locale.languageCode;

    testWidgets('list ($lang)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = await tester.runAsync(_withSamples) ??
          (throw StateError('no samples'));
      addTearDown(c.dispose);
      await tester.pumpWidget(_app(c, locale,
          const Scaffold(body: SafeArea(child: RecurringPage()))));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/1_list_$lang.png'));
    });

    testWidgets('add form ($lang)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3300);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = await tester.runAsync(_withSamples) ??
          (throw StateError('no samples'));
      addTearDown(c.dispose);
      await tester.pumpWidget(_app(
          c,
          locale,
          const Scaffold(body: SafeArea(child: SubscriptionEditorSheet()))));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Net');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/2_add_$lang.png'));
    });

    testWidgets('edit form ($lang)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ProviderContainer c = await tester.runAsync(_withSamples) ??
          (throw StateError('no samples'));
      addTearDown(c.dispose);
      final SubscriptionItem item = (await tester.runAsync(() async {
        final Subscription sub = (await c.read(subscriptionsProvider.future))
            .firstWhere((Subscription s) => s.provider == 'Spotify');
        final RecurringRule rule = (await c.read(recurringRulesProvider.future))
            .firstWhere((RecurringRule r) => r.id == sub.ruleId);
        return (sub: sub, rule: rule);
      }))!;
      await tester.pumpWidget(_app(
          c,
          locale,
          Scaffold(
              body: SafeArea(
                  child: SubscriptionEditorSheet(existing: item)))));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/3_edit_trial_$lang.png'));
    });
  }
}
