import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/presentation/invite_rewards_card.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget _host({
  String? code,
  ReferralProgress progress = ReferralProgress.none,
  Set<ReferralReward> earned = const <ReferralReward>{},
  Locale locale = const Locale('ar'),
}) =>
    ProviderScope(
      overrides: <Override>[
        referralCodeProvider.overrideWith((Ref ref) async => code),
        referralProgressProvider.overrideWith((Ref ref) async => progress),
        referralGrantsProvider.overrideWith((Ref ref) async => earned),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: const Scaffold(
          body: SingleChildScrollView(child: InviteRewardsCard()),
        ),
      ),
    );

Future<AppLocalizations> _l([Locale l = const Locale('ar')]) =>
    AppLocalizations.delegate.load(l);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('signed out: it asks for an account instead of a dead button',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    final AppLocalizations l = await _l();
    expect(find.text(l.inviteNeedAccount), findsOneWidget);
    expect(find.text(l.shareCopyLink), findsNothing);
  });

  testWidgets('signed in: the link carries the code, left to right in Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(code: 'AB23CD45'));
    await tester.pumpAndSettle();
    final Finder link = find.textContaining('ref=AB23CD45');
    expect(link, findsOneWidget);
    // An Arabic layout must not reverse a Latin URL.
    expect(tester.widget<Text>(link).textDirection, TextDirection.ltr);
    expect(find.text((await _l()).shareCopyLink), findsOneWidget);
  });

  testWidgets('progress counts the ones who started, not the ones who joined',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
        code: 'AB23CD45',
        progress: const ReferralProgress(joined: 5, activated: 2)));
    await tester.pumpAndSettle();
    final AppLocalizations l = await _l();
    expect(find.text(l.inviteProgressLine(2, 3)), findsOneWidget);
    final LinearProgressIndicator bar =
        tester.widget(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(2 / 3, 0.001));
  });

  testWidgets('the three steps are locked until the friends are there',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(code: 'AB23CD45'));
    await tester.pumpAndSettle();
    final AppLocalizations l = await _l();
    expect(find.byIcon(Icons.lock_outline_rounded),
        findsNWidgets(ReferralReward.values.length));
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    for (final int n in <int>[3, 6, 9]) {
      expect(find.text(l.journeyStepFriends(n)), findsOneWidget);
    }
    expect(find.text(l.journeyPickTitle), findsNothing);
  });

  testWidgets('a picked reward is marked on its step, and only that one',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      code: 'AB23CD45',
      progress: const ReferralProgress(joined: 3, activated: 3),
      earned: const <ReferralReward>{ReferralReward.salarySplit},
    ));
    await tester.pumpAndSettle();
    final AppLocalizations l = await _l();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded),
        findsNWidgets(ReferralReward.values.length - 1));
    expect(find.text(l.planFeatSalarySplit), findsOneWidget);
    // The one pick is used: nothing is waiting.
    expect(find.text(l.journeyPickTitle), findsNothing);
  });

  testWidgets('three friends and nothing picked: the pick is offered',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      code: 'AB23CD45',
      progress: const ReferralProgress(joined: 3, activated: 3),
    ));
    // The waiting gift breathes forever, so this never "settles".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final AppLocalizations l = await _l();
    expect(find.text(l.journeyPickTitle), findsOneWidget);
    // Every reward is on offer.
    expect(find.text(l.planFeatSalarySplit), findsOneWidget);
    expect(find.text(l.featHealthDetails), findsOneWidget);
    expect(find.text(l.rewardHigherLimits), findsOneWidget);
  });

  testWidgets('it reads in English too, and names no invited person',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
        code: 'AB23CD45',
        progress: const ReferralProgress(joined: 2, activated: 1),
        locale: const Locale('en')));
    await tester.pumpAndSettle();
    final AppLocalizations l = await _l(const Locale('en'));
    expect(find.text(l.journeyTitle), findsOneWidget);
    expect(find.text(l.inviteProgressLine(1, 3)), findsOneWidget);
    // The card shows counts; it must never have a name or an address on it.
    expect(find.textContaining('@'), findsNothing);
  });

  test('every language has the invite strings', () async {
    for (final Locale loc in AppLocalizations.supportedLocales) {
      final AppLocalizations l = await AppLocalizations.delegate.load(loc);
      for (final String s in <String>[
        l.journeyTitle,
        l.journeyPickTitle,
        l.journeyPickHint,
        l.journeyPickFailed,
        l.journeyAllDone,
        l.journeyCelebrateReady,
        l.journeyStepFriends(3),
        l.journeyCelebrateJoined(2),
        l.inviteBody,
        l.inviteLink,
        l.inviteCopied,
        l.inviteRewards,
        l.inviteUnlocked,
        l.inviteNeedAccount,
        l.rewardHigherLimits,
      ]) {
        expect(s.trim(), isNotEmpty, reason: loc.languageCode);
      }
      expect(l.inviteProgressLine(2, 3), contains('2'),
          reason: '${loc.languageCode} must place the count');
    }
  });
}
