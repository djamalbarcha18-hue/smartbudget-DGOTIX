import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/share/presentation/share_app_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<void> _pump(WidgetTester tester,
    {required int activated, String? code = 'AB23CD45'}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      referralCodeProvider.overrideWith((_) async => code),
      referralProgressProvider
          .overrideWith((_) async => ReferralProgress(activated: activated)),
      referralGrantsProvider
          .overrideWith((_) async => const <ReferralReward>{}),
      welcomeGiftProvider.overrideWith((_) async => null),
    ],
    child: MaterialApp(
      theme: DsTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ShareAppSheet()),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the share sheet shows the ladder and the progress',
      (WidgetTester tester) async {
    await _pump(tester, activated: 1);
    for (final String s in <String>['3 friends', '6 friends', '9 friends']) {
      expect(find.text(s), findsOneWidget);
    }
    expect(find.text('1 of 3 joined and started'), findsOneWidget);
    // The share channels are still there.
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('three friends: the pick is offered right in the share sheet',
      (WidgetTester tester) async {
    await _pump(tester, activated: 3);
    expect(find.text('Your reward is ready: pick it'), findsOneWidget);
  });

  testWidgets('signed out: no ladder, the sharing stays as it was',
      (WidgetTester tester) async {
    await _pump(tester, activated: 0, code: null);
    expect(find.text('3 friends'), findsNothing);
    expect(find.text('WhatsApp'), findsOneWidget);
  });
}
