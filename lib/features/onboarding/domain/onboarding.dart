/// First-run checklist: the few steps that make SmartBudget useful, each one
/// ticked off from the user's real data where possible.
library;

enum OnboardingStepId { settings, transaction, budget, goal, guide }

class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.route,
    required this.done,
  });

  final OnboardingStepId id;

  /// Where tapping the step takes the user.
  final String route;
  final bool done;
}

/// The checklist in display order. Pure, so it is trivially testable.
List<OnboardingStep> buildOnboardingSteps({
  required bool visitedSettings,
  required bool visitedGuide,
  required bool hasTransaction,
  required bool hasBudget,
  required bool hasGoal,
}) =>
    <OnboardingStep>[
      OnboardingStep(
          id: OnboardingStepId.settings,
          route: '/settings',
          done: visitedSettings),
      OnboardingStep(
          id: OnboardingStepId.transaction,
          route: '/transactions',
          done: hasTransaction),
      OnboardingStep(
          id: OnboardingStepId.budget, route: '/budget', done: hasBudget),
      OnboardingStep(id: OnboardingStepId.goal, route: '/goals', done: hasGoal),
      OnboardingStep(
          id: OnboardingStepId.guide, route: '/guide', done: visitedGuide),
    ];

/// Persisted onboarding flags (the rest is derived from real data).
class OnboardingFlags {
  const OnboardingFlags({
    this.dismissed = false,
    this.visitedSettings = false,
    this.visitedGuide = false,
  });

  final bool dismissed;
  final bool visitedSettings;
  final bool visitedGuide;

  OnboardingFlags copyWith({
    bool? dismissed,
    bool? visitedSettings,
    bool? visitedGuide,
  }) =>
      OnboardingFlags(
        dismissed: dismissed ?? this.dismissed,
        visitedSettings: visitedSettings ?? this.visitedSettings,
        visitedGuide: visitedGuide ?? this.visitedGuide,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'd': dismissed,
        's': visitedSettings,
        'g': visitedGuide,
      };

  static OnboardingFlags fromJson(Map<String, dynamic> j) => OnboardingFlags(
        dismissed: j['d'] == true,
        visitedSettings: j['s'] == true,
        visitedGuide: j['g'] == true,
      );
}
