import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/analytics/application/alerts_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/goals/presentation/goal_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<List<Goal>> async = ref.watch(goalsProvider);
    final AlertFocus? focus = ref.watch(alertFocusProvider);
    final String? focusGoalId =
        (focus != null && focus.route == '/goals') ? focus.key : null;

    final Widget addBtn = DsButton(
      label: l.addGoal,
      icon: Icons.add_rounded,
      onPressed: () => GoalEditorSheet.show(context),
    );

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (context.isMobile) ...<Widget>[
            Text(l.navGoals, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DsSpacing.md),
            addBtn,
          ] else
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(l.navGoals,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                addBtn,
              ],
            ),
          const SizedBox(height: DsSpacing.lg),
          Expanded(
            child: async.when(
              loading: () => const DsLoading(),
              error: (Object e, _) => DsError(message: e.toString()),
              data: (List<Goal> goals) => goals.isEmpty
                  ? DsEmpty(
                      title: l.emptyGoalsTitle,
                      message: l.emptyGoalsMessage,
                      icon: Icons.flag_outlined,
                    )
                  : ListView.separated(
                      itemCount: goals.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DsSpacing.md),
                      itemBuilder: (BuildContext context, int i) => _GoalCard(
                        goal: goals[i],
                        highlighted: goals[i].id == focusGoalId,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, this.highlighted = false});
  final Goal goal;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;

    final double progress = GoalCalculator.progress(goal);
    final GoalStatus status = GoalCalculator.status(goal);
    final Money installment = GoalCalculator.monthlyInstallment(goal);
    final int? months = GoalCalculator.monthsRemaining(goal);
    final Color barColor = switch (status) {
      GoalStatus.completed => c.income,
      GoalStatus.saving => c.saving,
      GoalStatus.notStarted => c.textFaint,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: DsRadius.brLg,
        border: Border.all(
          color: highlighted ? c.brand : Colors.transparent,
          width: 2,
        ),
        boxShadow: highlighted
            ? <BoxShadow>[
                BoxShadow(
                    color: c.brand.withValues(alpha: 0.22), blurRadius: 16),
              ]
            : null,
      ),
      child: GlassCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(goal.name,
                    style: t.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _GoalStatusBadge(status: status),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await GoalEditorSheet.show(context, existing: goal);
                  } else if (v == 'delete') {
                    await ref.read(goalActionsProvider).delete(goal.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: c.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: DsSpacing.md),
              Text(MoneyFormatter.percent(progress),
                  style: t.labelLarge?.copyWith(color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.xl,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              _Metric(label: l.goalSaved, value: MoneyFormatter.format(goal.saved)),
              _Metric(label: l.fieldTarget, value: MoneyFormatter.format(goal.target)),
              _Metric(label: l.goalMonthly, value: MoneyFormatter.format(installment)),
              if (months != null)
                _Metric(label: l.goalMonthsLeft(months), value: ''),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DsSpacing.md),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _recommendation(goal, l),
              style: t.bodySmall?.copyWith(color: c.textMuted),
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.goalContribute,
            icon: Icons.add_rounded,
            variant: DsButtonVariant.secondary,
            onPressed: () => _contribute(context, ref, goal, l),
          ),
        ],
      ),
      ),
    );
  }

  String _recommendation(Goal g, AppLocalizations l) {
    final String amount =
        MoneyFormatter.format(GoalCalculator.monthlyInstallment(g));
    return switch (GoalCalculator.urgency(g)) {
      GoalUrgency.achieved => l.recoAchieved,
      GoalUrgency.expired => l.recoExpired,
      GoalUrgency.relaxed => l.recoRelaxed(amount),
      GoalUrgency.balanced => l.recoBalanced(amount),
      GoalUrgency.urgent => l.recoUrgent(amount),
    };
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    Goal g,
    AppLocalizations l,
  ) async {
    final TextEditingController amount = TextEditingController();
    final String currency = ref.read(baseCurrencyProvider);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.contributeTo(g.name)),
        content: TextField(
          inputFormatters: LatinDigitsFormatter.only,
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.fieldAmount),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok == true) {
      final double n =
          double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
      if (n > 0) {
        await ref
            .read(goalActionsProvider)
            .contribute(g, Money.fromDouble(n, currency));
      }
    }
    amount.dispose();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: t.labelSmall?.copyWith(color: c.textFaint)),
        if (value.isNotEmpty)
          Text(value, style: t.titleSmall?.copyWith(color: c.textPrimary)),
      ],
    );
  }
}

class _GoalStatusBadge extends StatelessWidget {
  const _GoalStatusBadge({required this.status});
  final GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final (String, DsBadgeTone) data = switch (status) {
      GoalStatus.completed => (l.goalStatusCompleted, DsBadgeTone.income),
      GoalStatus.saving => (l.goalStatusSaving, DsBadgeTone.warning),
      GoalStatus.notStarted => (l.goalStatusNotStarted, DsBadgeTone.neutral),
    };
    return DsBadge(label: data.$1, tone: data.$2);
  }
}
