import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/onboarding/application/onboarding_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';

/// Wraps a screen and ticks off its onboarding step the first time it opens,
/// however the user got there (sidebar, search, or the welcome card). Keeps
/// the screens themselves unaware of onboarding.
class OnboardingVisitMarker extends ConsumerStatefulWidget {
  const OnboardingVisitMarker({
    super.key,
    required this.step,
    required this.child,
  });

  final OnboardingStepId step;
  final Widget child;

  @override
  ConsumerState<OnboardingVisitMarker> createState() =>
      _OnboardingVisitMarkerState();
}

class _OnboardingVisitMarkerState extends ConsumerState<OnboardingVisitMarker> {
  @override
  void initState() {
    super.initState();
    // After the first frame: never mutate providers during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final OnboardingController ctl =
          ref.read(onboardingFlagsProvider.notifier);
      switch (widget.step) {
        case OnboardingStepId.settings:
          ctl.markSettingsVisited();
        case OnboardingStepId.guide:
          ctl.markGuideVisited();
        case OnboardingStepId.transaction:
        case OnboardingStepId.budget:
        case OnboardingStepId.goal:
          break; // derived from real data, nothing to mark
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
