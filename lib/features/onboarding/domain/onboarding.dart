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

/// The checklist in display order: the three things that make the app useful,
/// the first expense first. Pure, so it is trivially testable.
///
/// Choosing a language and currency and reading the guide used to be steps
/// too. The currency is now picked from the device's country and confirmed on
/// the card itself, and the guide is a link under it, so a new user's first
/// step is the one that matters.
List<OnboardingStep> buildOnboardingSteps({
  required bool hasTransaction,
  required bool hasBudget,
  required bool hasGoal,
}) =>
    <OnboardingStep>[
      OnboardingStep(
          id: OnboardingStepId.transaction,
          route: '/transactions',
          done: hasTransaction),
      OnboardingStep(
          id: OnboardingStepId.budget, route: '/budget', done: hasBudget),
      OnboardingStep(id: OnboardingStepId.goal, route: '/goals', done: hasGoal),
    ];

/// The step to do next, or null when all are done.
OnboardingStep? nextOnboardingStep(List<OnboardingStep> steps) {
  for (final OnboardingStep s in steps) {
    if (!s.done) return s;
  }
  return null;
}

/// Persisted onboarding flags (the rest is derived from real data).
class OnboardingFlags {
  const OnboardingFlags({
    this.dismissed = false,
    this.visitedSettings = false,
    this.visitedGuide = false,
    this.firstSeenMs,
    this.reopened = false,
  });

  final bool dismissed;
  final bool visitedSettings;
  final bool visitedGuide;

  /// When this device first showed the card (null until the first load has
  /// settled). The card is only for a new user, so it ends a week after.
  final int? firstSeenMs;

  /// The user asked for the checklist back (from the guide): it shows
  /// whatever the week or the data say, until dismissed again.
  final bool reopened;

  OnboardingFlags copyWith({
    bool? dismissed,
    bool? visitedSettings,
    bool? visitedGuide,
    int? firstSeenMs,
    bool? reopened,
  }) =>
      OnboardingFlags(
        dismissed: dismissed ?? this.dismissed,
        visitedSettings: visitedSettings ?? this.visitedSettings,
        visitedGuide: visitedGuide ?? this.visitedGuide,
        firstSeenMs: firstSeenMs ?? this.firstSeenMs,
        reopened: reopened ?? this.reopened,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'd': dismissed,
        's': visitedSettings,
        'g': visitedGuide,
        if (firstSeenMs != null) 'f': firstSeenMs,
        if (reopened) 'r': true,
      };

  static OnboardingFlags fromJson(Map<String, dynamic> j) => OnboardingFlags(
        dismissed: j['d'] == true,
        visitedSettings: j['s'] == true,
        visitedGuide: j['g'] == true,
        firstSeenMs: j['f'] is int ? j['f'] as int : null,
        reopened: j['r'] == true,
      );
}

/// How long the welcome card may stay for a new user.
const Duration kWelcomeWindow = Duration(days: 7);

/// Transactions from which someone is plainly not new (also covers an
/// existing user whose data is still arriving from sync on a new device).
const int kEstablishedTransactions = 5;

/// Whether the dashboard shows the welcome checklist. It is for a NEW user:
/// not once dismissed, not after the first week, not once the three steps (a
/// transaction, a budget, a goal) are done, and not for someone who already
/// has plenty of records, such as an existing user signing in on another
/// device.
bool shouldShowWelcome({
  required OnboardingFlags flags,
  required List<OnboardingStep> steps,
  required int transactionCount,
  required DateTime now,
}) {
  if (flags.dismissed) return false;
  if (flags.reopened) return true;
  final int? first = flags.firstSeenMs;
  if (first != null &&
      now.difference(DateTime.fromMillisecondsSinceEpoch(first)) >
          kWelcomeWindow) {
    return false;
  }
  if (transactionCount >= kEstablishedTransactions) return false;
  // Setting up is finished: leave the dashboard to the figures.
  if (steps.every((OnboardingStep s) => s.done)) return false;
  return true;
}
