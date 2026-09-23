import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/onboarding/application/onboarding_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// First-run welcome card for the dashboard: a short checklist that ticks
/// itself off from the user's real data and links to each step. Hidden once
/// dismissed, and never shown half-loaded.
class WelcomeCard extends ConsumerWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingFlags? flags = ref.watch(onboardingFlagsProvider);
    final List<OnboardingStep>? steps = ref.watch(onboardingStepsProvider);
    if (flags == null || flags.dismissed || steps == null) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final int done = steps.where((OnboardingStep s) => s.done).length;
    final bool allDone = done == steps.length;
    final OnboardingController ctl = ref.read(onboardingFlagsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xl),
      child: GlassCard(
        accent: c.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                    allDone
                        ? Icons.celebration_outlined
                        : Icons.waving_hand_outlined,
                    size: 22,
                    color: c.brand),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(allDone ? l.onbDoneTitle : l.onbTitle,
                          style: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(allDone ? l.onbDoneSubtitle : l.onbSubtitle,
                          style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.onbHide,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                  onPressed: ctl.dismiss,
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: DsRadius.brPill,
                    child: LinearProgressIndicator(
                      value: steps.isEmpty ? 0 : done / steps.length,
                      minHeight: 6,
                      backgroundColor: c.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(c.brand),
                    ),
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Text(l.onbProgress(done, steps.length),
                    style: t.labelSmall?.copyWith(color: c.textMuted)),
              ],
            ),
            if (!allDone) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              for (int i = 0; i < steps.length; i++)
                _StepRow(
                  index: i + 1,
                  step: steps[i],
                  label: _label(l, steps[i].id),
                  // Opening settings/guide ticks itself off (visit marker).
                  onTap: () => context.go(steps[i].route),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations l, OnboardingStepId id) => switch (id) {
        OnboardingStepId.settings => l.onbStepSettings,
        OnboardingStepId.transaction => l.onbStepTransaction,
        OnboardingStepId.budget => l.onbStepBudget,
        OnboardingStepId.goal => l.onbStepGoal,
        OnboardingStepId.guide => l.onbStepGuide,
      };
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.label,
    required this.onTap,
  });

  final int index;
  final OnboardingStep step;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: DsRadius.brMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
        child: Row(
          children: <Widget>[
            if (step.done)
              Icon(Icons.check_circle_rounded, size: 22, color: c.income)
            else
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border, width: 1.5),
                ),
                child: Text('$index',
                    style: t.labelSmall?.copyWith(color: c.textMuted)),
              ),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Text(
                label,
                style: t.bodyMedium?.copyWith(
                  color: step.done ? c.textMuted : c.textPrimary,
                  decoration: step.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
