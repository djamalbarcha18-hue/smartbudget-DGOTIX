import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/onboarding/domain/onboarding.dart';

void main() {
  welcomeTests();
  test('a brand-new user has three steps, the first entry first', () {
    final List<OnboardingStep> steps = buildOnboardingSteps(
      hasTransaction: false,
      hasBudget: false,
      hasGoal: false,
    );
    expect(steps.map((OnboardingStep s) => s.id).toList(), <OnboardingStepId>[
      OnboardingStepId.transaction,
      OnboardingStepId.budget,
      OnboardingStepId.goal,
    ]);
    expect(steps.every((OnboardingStep s) => !s.done), isTrue);
  });

  test('steps tick off from real data', () {
    final List<OnboardingStep> steps = buildOnboardingSteps(
      hasTransaction: true,
      hasBudget: false,
      hasGoal: true,
    );
    final Map<OnboardingStepId, bool> done = <OnboardingStepId, bool>{
      for (final OnboardingStep s in steps) s.id: s.done,
    };
    expect(done[OnboardingStepId.transaction], isTrue);
    expect(done[OnboardingStepId.budget], isFalse);
    expect(done[OnboardingStepId.goal], isTrue);
  });

  test('the next step is the first one left, in order', () {
    OnboardingStepId? next({bool tx = false, bool b = false, bool g = false}) =>
        nextOnboardingStep(buildOnboardingSteps(
                hasTransaction: tx, hasBudget: b, hasGoal: g))
            ?.id;
    expect(next(), OnboardingStepId.transaction);
    expect(next(tx: true), OnboardingStepId.budget);
    expect(next(tx: true, g: true), OnboardingStepId.budget);
    expect(next(tx: true, b: true), OnboardingStepId.goal);
    expect(next(tx: true, b: true, g: true), isNull);
  });

  test('every step links to an app route', () {
    for (final OnboardingStep s in buildOnboardingSteps(
      hasTransaction: false,
      hasBudget: false,
      hasGoal: false,
    )) {
      expect(s.route, startsWith('/'));
    }
  });

  test('flags survive a JSON round-trip; unknown input is safe', () {
    const OnboardingFlags f = OnboardingFlags(
        dismissed: true, visitedSettings: true, visitedGuide: false);
    final OnboardingFlags back = OnboardingFlags.fromJson(f.toJson());
    expect(back.dismissed, isTrue);
    expect(back.visitedSettings, isTrue);
    expect(back.visitedGuide, isFalse);
    final OnboardingFlags empty =
        OnboardingFlags.fromJson(const <String, dynamic>{});
    expect(empty.dismissed, isFalse);
  });
}

void welcomeTests() {
  final DateTime now = DateTime(2026, 11, 6);
  int ms(DateTime d) => d.millisecondsSinceEpoch;
  List<OnboardingStep> steps({
    bool tx = false,
    bool budget = false,
    bool goal = false,
  }) =>
      buildOnboardingSteps(
        hasTransaction: tx,
        hasBudget: budget,
        hasGoal: goal,
      );

  group('the welcome card is for a new user only', () {
    test('a brand-new user sees it', () {
      expect(
          shouldShowWelcome(
              flags: OnboardingFlags(firstSeenMs: ms(now)),
              steps: steps(),
              transactionCount: 0,
              now: now),
          isTrue);
    });

    test('dismissed: never again', () {
      expect(
          shouldShowWelcome(
              flags: const OnboardingFlags(dismissed: true),
              steps: steps(),
              transactionCount: 0,
              now: now),
          isFalse);
    });

    test('a week after the first visit it ends by itself', () {
      final OnboardingFlags f = OnboardingFlags(
          firstSeenMs: ms(now.subtract(const Duration(days: 8))));
      expect(
          shouldShowWelcome(
              flags: f, steps: steps(), transactionCount: 0, now: now),
          isFalse);
      final OnboardingFlags g = OnboardingFlags(
          firstSeenMs: ms(now.subtract(const Duration(days: 6))));
      expect(
          shouldShowWelcome(
              flags: g, steps: steps(), transactionCount: 0, now: now),
          isTrue);
    });

    test('the three steps done: it leaves the dashboard to the figures', () {
      expect(
          shouldShowWelcome(
              flags: OnboardingFlags(firstSeenMs: ms(now)),
              steps: steps(tx: true, budget: true, goal: true),
              transactionCount: 3,
              now: now),
          isFalse);
    });

    test('setting up still in progress keeps it', () {
      expect(
          shouldShowWelcome(
              flags: OnboardingFlags(firstSeenMs: ms(now)),
              steps: steps(tx: true),
              transactionCount: 1,
              now: now),
          isTrue);
    });

    test('an existing user on a new device (plenty of records) never sees it',
        () {
      expect(
          shouldShowWelcome(
              flags: OnboardingFlags(firstSeenMs: ms(now)),
              steps: steps(tx: true),
              transactionCount: kEstablishedTransactions,
              now: now),
          isFalse);
    });

    test('asked back from the guide: it shows whatever else says', () {
      expect(
          shouldShowWelcome(
              flags: OnboardingFlags(
                  firstSeenMs: ms(now.subtract(const Duration(days: 30))),
                  reopened: true),
              steps: steps(tx: true, budget: true, goal: true),
              transactionCount: 50,
              now: now),
          isTrue);
    });

    test('flags keep the first-seen time and the reopen choice', () {
      final OnboardingFlags back = OnboardingFlags.fromJson(
          const OnboardingFlags(firstSeenMs: 123, reopened: true).toJson());
      expect(back.firstSeenMs, 123);
      expect(back.reopened, isTrue);
      expect(OnboardingFlags.fromJson(const <String, dynamic>{}).firstSeenMs,
          isNull);
    });
  });
}
