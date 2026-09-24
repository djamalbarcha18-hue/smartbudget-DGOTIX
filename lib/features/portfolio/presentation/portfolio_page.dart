import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/portfolio_planner.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/portfolio/presentation/horizon_labels.dart';
import 'package:smartbudget/features/portfolio/presentation/project_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Smart Projects Portfolio — near / mid / long-term compartments with a
/// waterfall funding engine (see [PortfolioPlanner]).
class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Project> projects =
        ref.watch(projectsProvider).valueOrNull ?? const <Project>[];
    final PortfolioPlan plan = ref.watch(portfolioPlanProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(l.navPortfolio,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis),
              ),
              DsButton(
                label: l.addProject,
                icon: Icons.add_rounded,
                onPressed: () => ProjectEditorSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.portfolioSubtitle,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: DsSpacing.xl),
          _FeasibilityCard(plan: plan),
          const SizedBox(height: DsSpacing.xl),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.xxl),
              child: Center(
                child: Text(l.portfolioEmpty,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            )
          else
            for (final ProjectHorizon h in ProjectHorizon.values) ...<Widget>[
              _HorizonSection(horizon: h, plans: plan.forHorizon(h)),
              const SizedBox(height: DsSpacing.lg),
            ],
        ],
      ),
    );
  }
}

/// The genius centrepiece: capacity vs. what the portfolio needs each month,
/// and whether everything is funded on time.
class _FeasibilityCard extends ConsumerWidget {
  const _FeasibilityCard({required this.plan});
  final PortfolioPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final Money suggested = ref.watch(suggestedCapacityProvider);
    final bool feasible = plan.feasible;
    final Color tone = plan.capacity.minorUnits == 0
        ? c.textMuted
        : (feasible ? c.income : c.warning);

    return GlassCard(
      accent: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.waterfall_chart_rounded, size: 18, color: tone),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.portfolioFundingTitle,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.xl,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              _Metric(
                label: l.monthlyCapacity,
                value: plan.capacity.minorUnits == 0
                    ? '—'
                    : MoneyFormatter.format(plan.capacity),
              ),
              _Metric(
                label: l.requiredMonthlyTotal,
                value: MoneyFormatter.format(plan.totalRequiredMonthly),
              ),
              _Metric(
                label: feasible ? l.monthlySurplus : l.monthlyShortfall,
                value: MoneyFormatter.format(
                    feasible ? plan.surplus : plan.shortfall),
                valueColor: feasible ? c.income : c.warning,
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md, vertical: DsSpacing.sm),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: DsRadius.brMd,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                    plan.capacity.minorUnits == 0
                        ? Icons.info_outline_rounded
                        : (feasible
                            ? Icons.check_circle_outline_rounded
                            : Icons.priority_high_rounded),
                    size: 16,
                    color: tone),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    plan.capacity.minorUnits == 0
                        ? l.portfolioSetCapacity
                        : (feasible
                            ? l.portfolioFullyFunded
                            : l.portfolioNeedsMore(
                                MoneyFormatter.format(plan.shortfall))),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: <Widget>[
              DsButton(
                label: l.setCapacity,
                icon: Icons.tune_rounded,
                variant: DsButtonVariant.secondary,
                onPressed: () => _editCapacity(context, ref),
              ),
              if (suggested.minorUnits > 0) ...<Widget>[
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: TextButton(
                    onPressed: () => ref
                        .read(portfolioCapacityProvider.notifier)
                        .set(suggested.minorUnits),
                    child: Text(
                      l.useSuggested(MoneyFormatter.format(suggested)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editCapacity(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final int current = ref.read(portfolioCapacityProvider);
    final TextEditingController ctrl = TextEditingController(
      text: current == 0 ? '' : Money(current, currency).asDouble.toString(),
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.monthlyCapacity),
        content: TextField(
          inputFormatters: LatinDigitsFormatter.only,
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.fieldAmount),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok == true) {
      final double n =
          double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
      await ref
          .read(portfolioCapacityProvider.notifier)
          .set(Money.fromDouble(n, currency).minorUnits);
    }
    ctrl.dispose();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? c.textPrimary)),
      ],
    );
  }
}

class _HorizonSection extends StatelessWidget {
  const _HorizonSection({required this.horizon, required this.plans});
  final ProjectHorizon horizon;
  final List<ProjectPlan> plans;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    if (plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              left: DsSpacing.xs, right: DsSpacing.xs, bottom: DsSpacing.sm),
          child: Row(
            children: <Widget>[
              Text(horizonLabel(horizon, l),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: DsSpacing.sm),
              Text(horizonSubtitle(horizon, l),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.textFaint)),
            ],
          ),
        ),
        for (final ProjectPlan p in plans) ...<Widget>[
          _ProjectCard(plan: p),
          const SizedBox(height: DsSpacing.sm),
        ],
      ],
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.plan});
  final ProjectPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final Project p = plan.project;
    final double progress = plan.progress.clamp(0.0, 1.0);
    final (Color, String) badge = _statusBadge(plan.status, c, l);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(p.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
              ),
              _StatusChip(color: badge.$1, label: badge.$2),
              _CardMenu(plan: plan),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            children: <Widget>[
              Text(MoneyFormatter.format(p.saved),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: c.textPrimary)),
              Text('  /  ${MoneyFormatter.format(p.target)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.textMuted)),
              const Spacer(),
              Text('${(progress * 100).round()}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: c.brand)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                  plan.status == ProjectFundStatus.overdue
                      ? c.expense
                      : c.saving),
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.lg,
            runSpacing: DsSpacing.xs,
            children: <Widget>[
              _MiniStat(
                  label: l.requiredMonthly,
                  value: MoneyFormatter.format(plan.requiredMonthly)),
              _MiniStat(
                  label: l.allocatedMonthly,
                  value: MoneyFormatter.format(plan.allocatedMonthly),
                  valueColor: plan.allocatedMonthly.minorUnits > 0
                      ? c.income
                      : c.textMuted),
              if (plan.monthsToCompleteAtPace != null)
                _MiniStat(
                    label: l.etaAtPace,
                    value: l.monthsShort(plan.monthsToCompleteAtPace!)),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DsButton(
              label: l.contribute,
              icon: Icons.add_card_outlined,
              variant: DsButtonVariant.secondary,
              onPressed: () => _contribute(context, ref, p),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _statusBadge(
      ProjectFundStatus s, DsColors c, AppLocalizations l) {
    return switch (s) {
      ProjectFundStatus.completed => (c.income, l.statusCompleted),
      ProjectFundStatus.funded => (c.income, l.statusFunded),
      ProjectFundStatus.partial => (c.warning, l.statusPartial),
      ProjectFundStatus.unfunded => (c.textMuted, l.statusUnfunded),
      ProjectFundStatus.overdue => (c.expense, l.statusOverdue),
    };
  }

  Future<void> _contribute(
      BuildContext context, WidgetRef ref, Project p) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.read(baseCurrencyProvider);
    final TextEditingController ctrl = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${l.contribute} · ${p.name}'),
        content: TextField(
          inputFormatters: LatinDigitsFormatter.only,
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.fieldAmount),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok == true) {
      final double n =
          double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
      if (n > 0) {
        await ref
            .read(projectActionsProvider)
            .contribute(p, Money.fromDouble(n, currency));
      }
    }
    ctrl.dispose();
  }
}

class _CardMenu extends ConsumerWidget {
  const _CardMenu({required this.plan});
  final ProjectPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textMuted),
      color: c.bgElevated,
      onSelected: (String v) {
        if (v == 'edit') {
          ProjectEditorSheet.show(context, existing: plan.project);
        } else if (v == 'delete') {
          ref.read(projectActionsProvider).delete(plan.project.id);
        }
      },
      itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
        PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c.textFaint)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: valueColor ?? c.textPrimary)),
      ],
    );
  }
}
