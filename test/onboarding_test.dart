import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/onboarding/domain/onboarding.dart';

void main() {
  test('a brand-new user has every step open, in order', () {
    final List<OnboardingStep> steps = buildOnboardingSteps(
      visitedSettings: false,
      visitedGuide: false,
      hasTransaction: false,
      hasBudget: false,
      hasGoal: false,
    );
    expect(steps.map((OnboardingStep s) => s.id).toList(), <OnboardingStepId>[
      OnboardingStepId.settings,
      OnboardingStepId.transaction,
      OnboardingStepId.budget,
      OnboardingStepId.goal,
      OnboardingStepId.guide,
    ]);
    expect(steps.every((OnboardingStep s) => !s.done), isTrue);
  });

  test('steps tick off from real data and visits', () {
    final List<OnboardingStep> steps = buildOnboardingSteps(
      visitedSettings: true,
      visitedGuide: false,
      hasTransaction: true,
      hasBudget: false,
      hasGoal: true,
    );
    final Map<OnboardingStepId, bool> done = <OnboardingStepId, bool>{
      for (final OnboardingStep s in steps) s.id: s.done,
    };
    expect(done[OnboardingStepId.settings], isTrue);
    expect(done[OnboardingStepId.transaction], isTrue);
    expect(done[OnboardingStepId.budget], isFalse);
    expect(done[OnboardingStepId.goal], isTrue);
    expect(done[OnboardingStepId.guide], isFalse);
  });

  test('every step links to an app route', () {
    for (final OnboardingStep s in buildOnboardingSteps(
      visitedSettings: false,
      visitedGuide: false,
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
