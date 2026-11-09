import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/presentation/invite_rewards_card.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class _Service implements ReferralService {
  final List<ReferralReward> chosen = <ReferralReward>[];
  bool accept = true;
  @override
  Future<bool> choose(ReferralReward r) async {
    chosen.add(r);
    return accept;
  }

  @override
  Future<bool> claim(String code) async => false;
  @override
  Future<bool> complete() async => false;
  @override
  Future<String?> code() async => 'AB23CD45';
  @override
  Future<ReferralProgress> progress() async => ReferralProgress.none;
  @override
  Future<Set<ReferralReward>> grants() async => const <ReferralReward>{};
}

Future<_Service> _pump(WidgetTester tester,
    {required int activated,
    List<ReferralReward> picked = const <ReferralReward>[],
    String? code = 'AB23CD45'}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 1500);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final _Service service = _Service();
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      referralServiceProvider.overrideWithValue(service),
      referralCodeProvider.overrideWith((_) async => code),
      referralProgressProvider
          .overrideWith((_) async => ReferralProgress(activated: activated)),
      referralGrantsProvider.overrideWith((_) async => picked.toSet()),
    ],
    child: MaterialApp(
      theme: DsTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: InviteRewardsCard()),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return service;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('no friends yet: the ladder, the target and the share button',
      (WidgetTester tester) async {
    await _pump(tester, activated: 0);
    expect(find.text('Rewards journey'), findsOneWidget);
    expect(find.text('0 of 3 joined and started'), findsOneWidget);
    expect(find.text('3 friends'), findsOneWidget);
    expect(find.text('6 friends'), findsOneWidget);
    expect(find.text('9 friends'), findsOneWidget);
    expect(find.text('Your reward is ready: pick it'), findsNothing);
    expect(find.text('Invite friends'), findsOneWidget);
  });

  testWidgets('three friends: a pick is waiting and the reward can be chosen',
      (WidgetTester tester) async {
    final _Service s = await _pump(tester, activated: 3);
    expect(find.text('Your reward is ready: pick it'), findsOneWidget);
    // All three are offered.
    expect(find.text('Smart salary split'), findsWidgets);
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.chosen, hasLength(1));
    // The celebration pops up.
    expect(find.text('Unlocked'), findsWidgets);
  });

  testWidgets('a pick the server refuses says so and unlocks nothing',
      (WidgetTester tester) async {
    final _Service s = await _pump(tester, activated: 3);
    s.accept = false;
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Couldn't save your pick. Try again in a moment."),
        findsOneWidget);
  });

  testWidgets('everything picked: the thank-you replaces the progress',
      (WidgetTester tester) async {
    await _pump(tester, activated: 9, picked: ReferralReward.values);
    expect(find.text('You unlocked every reward. Thank you for spreading the word!'),
        findsOneWidget);
    expect(find.text('Your reward is ready: pick it'), findsNothing);
  });

  testWidgets('signed out: no ladder, a plain explanation',
      (WidgetTester tester) async {
    await _pump(tester, activated: 0, code: null);
    expect(find.text('3 friends'), findsNothing);
    expect(find.textContaining('Create an account'), findsOneWidget);
  });
}
