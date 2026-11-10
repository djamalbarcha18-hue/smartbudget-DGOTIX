import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/presentation/referral_celebration.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

final StateProvider<int> _count = StateProvider<int>((_) => 1);

Future<ProviderContainer> _pump(WidgetTester tester,
    {String? uid = 'u1', int seen = 1}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'flutter.${AccountKeys.of('sb_referral_seen', 'u1')}': seen,
  });
  final GoRouter router = GoRouter(routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
  ]);
  final ProviderContainer container = ProviderContainer(overrides: <Override>[
    currentAccountIdProvider.overrideWithValue(uid),
    referralProgressProvider.overrideWith(
        (Ref ref) async => ReferralProgress(activated: ref.watch(_count))),
    referralGrantsProvider
        .overrideWith((_) async => const <ReferralReward>{}),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: DsTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) =>
          ReferralCelebration(router: router, child: child!),
      home: const Scaffold(body: Text('home')),
    ),
  ));
  // Let the first count come in (and be recorded without a note).
  await tester.runAsync(() => Future<void>.delayed(
      const Duration(milliseconds: 50)));
  await tester.pump();
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('a new friend since last time shows a happy note',
      (WidgetTester tester) async {
    final ProviderContainer c = await _pump(tester);
    expect(find.byIcon(Icons.celebration_rounded), findsNothing,
        reason: 'the count on first sight is not news');
    c.read(_count.notifier).state = 2;
    await _settle(tester);
    expect(find.text('A friend joined! 1 more to go.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // it goes by itself
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
  });

  testWidgets('three friends: the note says the reward is ready',
      (WidgetTester tester) async {
    final ProviderContainer c = await _pump(tester, seen: 2);
    c.read(_count.notifier).state = 3;
    await _settle(tester);
    expect(find.text('Your reward is ready. Open Settings to pick it.'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('friends already counted on another device are not news',
      (WidgetTester tester) async {
    // Nothing stored on this device yet: the first count is just recorded.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final GoRouter router = GoRouter(routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
    ]);
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      currentAccountIdProvider.overrideWithValue('u1'),
      referralProgressProvider
          .overrideWith((_) async => const ReferralProgress(activated: 2)),
      referralGrantsProvider
          .overrideWith((_) async => const <ReferralReward>{}),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: DsTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) =>
            ReferralCelebration(router: router, child: child!),
        home: const Scaffold(body: Text('home')),
      ),
    ));
    await _settle(tester);
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
  });

  testWidgets('the welcome gift of an invited person is said once',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final GoRouter router = GoRouter(routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
    ]);
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      currentAccountIdProvider.overrideWithValue('u1'),
      referralProgressProvider
          .overrideWith((_) async => const ReferralProgress(activated: 0)),
      referralGrantsProvider
          .overrideWith((_) async => const <ReferralReward>{}),
      welcomeGiftProvider.overrideWith(
          (_) async => DateTime.now().subtract(const Duration(days: 1))),
    ]);
    addTearDown(container.dispose);
    Widget app() => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DsTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (BuildContext context, Widget? child) =>
                ReferralCelebration(router: router, child: child!),
            home: const Scaffold(body: Text('home')),
          ),
        );
    await tester.pumpWidget(app());
    await _settle(tester);
    expect(
        find.text(
            'A friend invited you, and here is your gift: the smart salary split, free for 30 days.'),
        findsOneWidget);
    // Opening the app again on this device does not repeat it.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    await _settle(tester);
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
  });

  testWidgets('signed out: nothing happens', (WidgetTester tester) async {
    final ProviderContainer c = await _pump(tester, uid: null);
    c.read(_count.notifier).state = 5;
    await _settle(tester);
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
  });
}
