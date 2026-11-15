import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_engine_page.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_page.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_pattern.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Over a full lunar year ago, whatever day the tests run.
final DateTime hawlStart = DateTime.now().subtract(const Duration(days: 400));

String day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<ProviderContainer> pump(
  WidgetTester tester, {
  required Map<String, Object> prefs,
  String currency = 'DZD',
  int walletMinor = 300000000,
  String locale = 'en',
}) async {
  SharedPreferences.setMockInitialValues(
      <String, Object>{'sb_base_currency': currency, ...prefs});
  tester.view.physicalSize = const Size(1170, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    walletsProvider.overrideWithValue(<Wallet>[
      Wallet.general(currency, opening: Money(walletMinor, currency)),
    ]),
  ]);
  addTearDown(c.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      home: const Scaffold(body: ZakatScreen()),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('an Algerian user sees the Maliki result and can confirm it',
      (WidgetTester tester) async {
    await pump(tester, prefs: <String, Object>{
      'sb_zakat_settings_guest':
          jsonEncode(<String, dynamic>{'v': 2, 'hawlStart': day(hawlStart)}),
    });
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.byType(ZakatEnginePage), findsOneWidget);
    expect(find.byType(ZakatPatternBackground), findsOneWidget);
    expect(find.text(l.zkSchoolMaliki), findsOneWidget);
    expect(find.text(l.zakatObligatory), findsOneWidget);
    final String due =
        (tester.widget<Text>(find.byKey(const Key('zakat-due')))).data!;
    expect(due.replaceAll(RegExp(r'[^0-9]'), ''), startsWith('75000'));
    expect(find.text(l.zkNotFatwa), findsOneWidget);
    expect(find.text(l.zkHistoryEmpty), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('zakat-confirm')));
    await tester.tap(find.byKey(const Key('zakat-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l.zkHistoryEmpty), findsNothing);
    expect(find.text(l.zkRulesVersion('dz-2026.11-maliki')), findsOneWidget);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('sb_zakat_history_guest')!), hasLength(1));
  });

  testWidgets('without a hawl start nothing is due and the date is asked for',
      (WidgetTester tester) async {
    await pump(tester, prefs: <String, Object>{});
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byKey(const Key('zakat-hawl-set')), findsOneWidget);
    expect(find.text(l.zakatObligatory), findsNothing);
    expect(find.text(l.zkIssueHawlStart), findsOneWidget);
  });

  testWidgets('the older inputs are read, flagged once, and left as they were',
      (WidgetTester tester) async {
    final String legacy = jsonEncode(<String, dynamic>{
      'gold': 36000,
      'silver': 250,
      'standard': 'gold',
      'hawlStart': hawlStart.toIso8601String(),
      'cash': 0,
      'metals': 0,
      'investments': 0,
    });
    await pump(tester, prefs: <String, Object>{'sb_zakat_inputs_guest': legacy});
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.zkMethodChanged), findsOneWidget);

    await tester.tap(find.text(l.zkGotIt));
    await tester.pumpAndSettle();
    expect(find.text(l.zkMethodChanged), findsNothing);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sb_zakat_inputs_guest'), legacy);
    expect(prefs.containsKey('sb_zakat_settings_guest'), isTrue);
  });

  testWidgets('other markets (Saudi Arabia included) keep the earlier screen',
      (WidgetTester tester) async {
    await pump(tester, prefs: <String, Object>{}, currency: 'SAR');
    expect(find.byType(ZakatPage), findsOneWidget);
    expect(find.byType(ZakatEnginePage), findsNothing);
  });

  testWidgets('reads right to left in Arabic', (WidgetTester tester) async {
    await pump(tester,
        locale: 'ar',
        prefs: <String, Object>{
          'sb_zakat_settings_guest': jsonEncode(
              <String, dynamic>{'v': 2, 'hawlStart': day(hawlStart)}),
        });
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l.zkSchoolMaliki), findsOneWidget);
    expect(find.text(l.zkConfirm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
