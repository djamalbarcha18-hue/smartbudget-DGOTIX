import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/onboarding/application/onboarding_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// First-run welcome card for the dashboard: a short checklist that ticks
/// itself off from the user's real data and links to each step. Hidden once
/// dismissed, and never shown half-loaded.
class WelcomeCard extends ConsumerWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OnboardingStep>? steps = ref.watch(onboardingStepsProvider);
    if (steps == null || !ref.watch(welcomeVisibleProvider)) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final int done = steps.where((OnboardingStep s) => s.done).length;
    final bool allDone = done == steps.length;
    // The one thing to do now. The card leads with it as a button; the chips
    // below only show where the user stands.
    final OnboardingStep? next = nextOnboardingStep(steps);
    final bool started = done > 0;
    final String base = ref.watch(baseCurrencyProvider);
    final OnboardingController ctl = ref.read(onboardingFlagsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.gridGap),
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
                      Text(
                          allDone
                              ? l.onbDoneTitle
                              : (started ? l.onbFirstDoneTitle : l.onbTitle),
                          style: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          allDone
                              ? l.onbDoneSubtitle
                              : switch (next?.id) {
                                  OnboardingStepId.income => started
                                      ? l.onbSubtitle
                                      : l.onbStartSubtitle,
                                  OnboardingStepId.transaction =>
                                    l.onbAfterIncomeSubtitle,
                                  OnboardingStepId.budget =>
                                    l.onbFirstDoneSubtitle,
                                  _ => l.onbSubtitle,
                                },
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
            if (next != null) ...<Widget>[
              const SizedBox(height: DsSpacing.md),
              DsButton(
                key: const ValueKey<String>('onb-next'),
                expand: true,
                label: _label(l, next.id),
                icon: switch (next.id) {
                  OnboardingStepId.income => Icons.south_west_rounded,
                  OnboardingStepId.transaction => Icons.north_east_rounded,
                  _ => Icons.arrow_forward_rounded,
                },
                onPressed: () => _open(context, next),
              ),
              // Before anything is recorded: the other way in, and the
              // currency the figures will be in.
              if (!started) ...<Widget>[
                const SizedBox(height: DsSpacing.xs),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DsSpacing.sm,
                  children: <Widget>[
                    TextButton(
                      key: const ValueKey<String>('onb-expense'),
                      onPressed: () => TransactionEditorSheet.show(context,
                          type: TransactionType.expense),
                      child: Text(l.onbOrExpense),
                    ),
                    // The currency was picked from the device's country: said
                    // here, with a way to change it, instead of sending a new
                    // user through the whole settings page first.
                    InkWell(
                      key: const ValueKey<String>('onb-currency'),
                      borderRadius: DsRadius.brPill,
                      onTap: () => context.go('/settings'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CurrencyFlag.code(base, width: 18),
                            const SizedBox(width: 6),
                            Text(l.onbCurrencyLine(base),
                                style:
                                    t.bodySmall?.copyWith(color: c.textMuted)),
                            const SizedBox(width: 6),
                            Text(l.onbChange,
                                style: t.bodySmall?.copyWith(
                                    color: c.brand,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: DsSpacing.sm),
              // Where the user stands: the steps, slim, under the button.
              Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: <Widget>[
                  for (int i = 0; i < steps.length; i++)
                    _StepRow(
                      index: i + 1,
                      step: steps[i],
                      label: _label(l, steps[i].id),
                      onTap: () => _open(context, steps[i]),
                    ),
                ],
              ),
            ],
            // The guide is always a tap away, without being a step to tick.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey<String>('onb-guide'),
                onPressed: () => context.go('/guide'),
                icon: const Icon(Icons.menu_book_outlined, size: 16),
                label: Text(l.guideTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A step's own place. The first income and the first expense open right
  /// here, over the dashboard: no page to find first.
  void _open(BuildContext context, OnboardingStep step) {
    if (!step.done && step.id == OnboardingStepId.income) {
      TransactionEditorSheet.show(context, type: TransactionType.income);
    } else if (!step.done && step.id == OnboardingStepId.transaction) {
      TransactionEditorSheet.show(context, type: TransactionType.expense);
    } else {
      context.go(step.route);
    }
  }

  String _label(AppLocalizations l, OnboardingStepId id) => switch (id) {
        OnboardingStepId.income => l.onbFirstIncome,
        OnboardingStepId.transaction => l.onbFirstExpense,
        OnboardingStepId.budget => l.onbStepBudget,
        OnboardingStepId.goal => l.onbStepGoal,
        // No longer steps of the checklist (kept for the visit markers).
        OnboardingStepId.settings => l.onbStepSettings,
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
      borderRadius: DsRadius.brPill,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: DsRadius.brPill,
          color: c.surfaceMuted,
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (step.done)
              Icon(Icons.check_circle_rounded, size: 18, color: c.income)
            else
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border, width: 1.5),
                ),
                child: Text('$index',
                    style: t.labelSmall?.copyWith(color: c.textMuted)),
              ),
            const SizedBox(width: DsSpacing.sm),
            // Long labels (Malay, Urdu…) wrap inside the pill.
            Flexible(
              child: Text(
                label,
                style: t.bodySmall?.copyWith(
                  color: step.done ? c.textMuted : c.textPrimary,
                  decoration: step.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
