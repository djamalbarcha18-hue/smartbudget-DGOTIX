import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';
import 'package:smartbudget/features/analytics/application/alerts_controller.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/analytics/presentation/alert_presentation.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

// ---------------------------------------------------------------------------
// "Month pulse" — three equal cards answering: am I within budget, how healthy
// am I, and what is about to be charged.
// ---------------------------------------------------------------------------

/// The shared shape of every pulse card, so the row reads as one unit: a
/// header, one large figure, a caption and an optional progress bar.
class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.caption,
    required this.onTap,
    this.valueColor,
    this.progress,
    this.progressColor,
  });

  final String title;
  final IconData icon;
  final String value;
  final String caption;
  final VoidCallback onTap;
  final Color? valueColor;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(
            title: title,
            icon: icon,
            trailing: Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: c.textFaint),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              // Figures read left-to-right even in Arabic ("91 / 100").
              textDirection: TextDirection.ltr,
              style: DsTypography.mono(t.headlineSmall ?? const TextStyle())
                  .copyWith(
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? c.textPrimary),
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.sm),
          ClipRRect(
            borderRadius: DsRadius.brPill,
            child: LinearProgressIndicator(
              value: (progress ?? 0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                  progress == null ? Colors.transparent : (progressColor ?? c.brand)),
            ),
          ),
        ],
      ),
    );
  }
}

/// This month's budget: how much of the planned spending is used.
class BudgetPulseCard extends ConsumerWidget {
  const BudgetPulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String currency = ref.watch(baseCurrencyProvider);
    final Map<String, Money> planned = ref.watch(monthPlannedByCategoryProvider);
    int plannedMinor = 0;
    for (final Money m in planned.values) {
      if (m.currencyCode == currency) plannedMinor += m.minorUnits;
    }
    final FinanceSummary month = ref.watch(monthlySummaryProvider);
    final int spent = month.expense.minorUnits;

    if (plannedMinor <= 0) {
      return _PulseCard(
        title: l.budgetThisMonth,
        icon: Icons.account_balance_wallet_outlined,
        value: '—',
        caption: l.budgetNotSet,
        onTap: () => context.go('/budget'),
      );
    }
    final double used = spent / plannedMinor;
    final Color tone =
        used > 1 ? c.expense : (used >= 0.8 ? c.warning : c.brand);
    return _PulseCard(
      title: l.budgetThisMonth,
      icon: Icons.account_balance_wallet_outlined,
      value: MoneyFormatter.percent(used, decimals: 0),
      valueColor: used > 1 ? c.expense : null,
      caption: l.budgetUsedCaption(
        MoneyFormatter.format(Money(spent, currency)),
        MoneyFormatter.format(Money(plannedMinor, currency)),
      ),
      progress: used,
      progressColor: tone,
      onTap: () => context.go('/budget'),
    );
  }
}

/// Health score colors, shared by the pulse card and its details dialog.
(String, Color) _healthMeta(HealthStatus s, AppLocalizations l, DsColors c) =>
    switch (s) {
      HealthStatus.excellent => (l.healthStatusExcellent, c.income),
      HealthStatus.veryGood => (l.healthStatusVeryGood, c.income),
      HealthStatus.good => (l.healthStatusGood, c.brand),
      HealthStatus.fair => (l.healthStatusFair, c.warning),
      HealthStatus.needsWork => (l.healthStatusNeedsWork, c.expense),
    };

/// The financial health score; tapping opens its indicators in a dialog.
class HealthPulseCard extends ConsumerWidget {
  const HealthPulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool hasData = ref.watch(healthHasDataProvider);
    final HealthReport r = ref.watch(healthReportProvider);
    final (String status, Color tone) = _healthMeta(r.status, l, c);
    return _PulseCard(
      title: l.sectionFinancialHealth,
      icon: Icons.monitor_heart_outlined,
      value: hasData ? '${r.score.round()} / 100' : '—',
      valueColor: hasData ? tone : null,
      caption: hasData ? status : l.healthEmpty,
      progress: hasData ? r.score / 100 : null,
      progressColor: tone,
      onTap: () => HealthDetailsDialog.show(context),
    );
  }
}

/// A focused view of the health score's indicators (pillars), with a link to
/// the full page.
class HealthDetailsDialog extends ConsumerWidget {
  const HealthDetailsDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const HealthDetailsDialog(),
      );

  static Color _scoreColor(DsColors c, double v) =>
      v >= 70 ? c.income : (v >= 50 ? c.warning : c.expense);

  static String _pillarName(HealthPillarKey k, AppLocalizations l) =>
      switch (k) {
        HealthPillarKey.cashFlow => l.hCashFlow,
        HealthPillarKey.savings => l.hSavings,
        HealthPillarKey.resilience => l.hResilience,
        HealthPillarKey.debt => l.hDebt,
        HealthPillarKey.incomeStability => l.hIncomeStability,
        HealthPillarKey.planning => l.hPlanning,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool hasData = ref.watch(healthHasDataProvider);
    final HealthReport r = ref.watch(healthReportProvider);
    final (String status, Color tone) = _healthMeta(r.status, l, c);

    Widget stat(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(DsSpacing.md),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: DsRadius.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: t.labelSmall),
                const SizedBox(height: 2),
                Text(value,
                    style: t.titleMedium?.copyWith(
                        color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );

    return Dialog(
      backgroundColor: c.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: DsSectionHeader(
                        title: l.sectionFinancialHealth,
                        icon: Icons.monitor_heart_outlined),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              if (!hasData)
                Text(l.healthEmpty, style: t.bodyMedium)
              else ...<Widget>[
                Row(
                  children: <Widget>[
                    // The score keeps its numeric (LTR) order in Arabic too.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text('${r.score.round()}',
                              style: DsTypography.mono(
                                      t.displaySmall ?? const TextStyle())
                                  .copyWith(color: tone)),
                          const SizedBox(width: DsSpacing.xs),
                          Text('/ 100', style: t.titleSmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: DsSpacing.md),
                    Expanded(
                      child: Text(status,
                          style: t.titleMedium?.copyWith(color: tone)),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.md),
                Row(
                  children: <Widget>[
                    stat(l.healthConfidence, '${r.confidence.round()}%',
                        c.textPrimary),
                    const SizedBox(width: DsSpacing.sm),
                    stat(l.healthResilience, '${r.resilience.round()}/100',
                        _scoreColor(c, r.resilience)),
                  ],
                ),
                const SizedBox(height: DsSpacing.lg),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: r.pillars.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DsSpacing.md),
                    itemBuilder: (BuildContext context, int i) {
                      final HealthPillar p = r.pillars[i];
                      final Color color =
                          p.available ? _scoreColor(c, p.score) : c.textFaint;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(_pillarName(p.key, l),
                                    style: t.titleSmall
                                        ?.copyWith(color: c.textPrimary)),
                              ),
                              Text(
                                  '${l.healthWeight} ${(p.weight * 100).round()}%',
                                  style: t.labelSmall),
                              const SizedBox(width: DsSpacing.md),
                              Text(
                                  p.available ? '${p.score.round()}' : '—',
                                  style: t.titleSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: DsRadius.brPill,
                            child: LinearProgressIndicator(
                              value: p.available
                                  ? (p.score / 100).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 6,
                              backgroundColor: c.surfaceMuted,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          if (!p.available) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(l.healthUnavailable,
                                style: t.labelSmall
                                    ?.copyWith(color: c.textFaint)),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: DsSpacing.lg),
              DsButton(
                label: l.viewDetails,
                icon: Icons.open_in_new_rounded,
                expand: true,
                variant: DsButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/health');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recurring items due in the next 7 days (the nearest one named).
class UpcomingPulseCard extends ConsumerWidget {
  const UpcomingPulseCard({super.key});

  static const int days = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<RecurringRule> rules =
        ref.watch(recurringRulesProvider).valueOrNull ?? const <RecurringRule>[];
    final DateTime today = RecurrenceEngine.dateOnly(DateTime.now());
    final DateTime limit = DateTime(today.year, today.month, today.day + days);

    final List<(RecurringRule, DateTime)> due = <(RecurringRule, DateTime)>[
      for (final RecurringRule r in rules)
        if (r.active)
          (r, RecurrenceEngine.nextOccurrence(r)),
    ]
        .where(((RecurringRule, DateTime) e) =>
            !e.$2.isBefore(today) && !e.$2.isAfter(limit))
        .toList()
      ..sort(((RecurringRule, DateTime) a, (RecurringRule, DateTime) b) =>
          a.$2.compareTo(b.$2));

    String caption = l.upcomingNone;
    if (due.isNotEmpty) {
      final RecurringRule r = due.first.$1;
      final String name = r.description.isNotEmpty
          ? r.description
          : Catalog.label(r.category, ar: ar);
      caption = l.upcomingNext(
          name, DateFormat('yyyy-MM-dd').format(due.first.$2));
    }
    return _PulseCard(
      title: l.upcomingTitle,
      icon: Icons.event_repeat_outlined,
      value: due.isEmpty ? '—' : '${due.length}',
      caption: caption,
      onTap: () => context.go('/recurring'),
    );
  }
}

// ---------------------------------------------------------------------------
// Side panels (the 4-column companions of the main panels).
// ---------------------------------------------------------------------------

/// Smart alerts beside the monthly chart. Never an empty block: with nothing
/// to flag it says so.
class AlertsPanel extends ConsumerWidget {
  const AlertsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final List<AppAlert> alerts = ref.watch(alertsProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(
              title: l.alertsSection,
              icon: Icons.notifications_active_outlined),
          const SizedBox(height: DsSpacing.md),
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.check_circle_outline_rounded,
                            size: 32, color: c.income),
                        const SizedBox(height: DsSpacing.sm),
                        Text(l.alertsAllClear,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: c.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: DsSpacing.md, color: c.border),
                    itemBuilder: (BuildContext context, int i) =>
                        _AlertRow(alert: alerts[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final AppAlert alert;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AlertView v = describeAlert(context, alert);
    return InkWell(
      borderRadius: DsRadius.brSm,
      onTap: () => context.go(v.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(v.icon, size: 16, color: v.color),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(v.title,
                      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(v.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "My plans": goals, debts and zakat as three compact rows in one card.
class PlansCard extends ConsumerWidget {
  const PlansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    final List<Goal> goals =
        ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    int saved = 0;
    int target = 0;
    for (final Goal g in goals) {
      saved += g.saved.minorUnits;
      target += g.target.minorUnits;
    }
    final double goalPct = target > 0 ? saved / target : 0;
    final DebtSummary debts = ref.watch(debtSummaryProvider);
    final zakat = ref.watch(zakatResultProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(title: l.myPlansTitle, icon: Icons.task_alt_outlined),
          const SizedBox(height: DsSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PlanRow(
                  icon: Icons.flag_outlined,
                  title: l.sectionGoals,
                  value: goals.isEmpty ? '—' : '${(goalPct * 100).round()}%',
                  caption: goals.isEmpty
                      ? l.emptyGoalsTitle
                      : '${goals.length} · ${l.goalSaved}',
                  progress: goals.isEmpty ? null : goalPct,
                  route: '/goals',
                ),
                Divider(height: 1, color: c.border),
                _PlanRow(
                  icon: Icons.account_balance_outlined,
                  title: l.sectionDebts,
                  value: MoneyFormatter.format(debts.net),
                  valueColor: debts.net.minorUnits >= 0 ? c.income : c.expense,
                  caption: '${l.debtNet} · ${debts.openCount}',
                  route: '/debts',
                ),
                Divider(height: 1, color: c.border),
                _PlanRow(
                  icon: Icons.mosque_outlined,
                  title: l.sectionZakat,
                  value: zakat.obligatory
                      ? MoneyFormatter.format(zakat.due)
                      : '—',
                  caption:
                      zakat.obligatory ? l.zakatObligatory : l.zakatNotDue,
                  route: '/zakat',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.route,
    this.valueColor,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final String route;
  final Color? valueColor;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: DsRadius.brMd,
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xs, vertical: DsSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: c.brand),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: t.titleSmall?.copyWith(color: c.textPrimary)),
                  Text(caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelSmall),
                  if (progress != null) ...<Widget>[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: DsRadius.brPill,
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: c.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(c.brand),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.md),
            Text(value,
                style: DsTypography.mono(t.titleMedium ?? const TextStyle())
                    .copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor ?? c.textPrimary)),
          ],
        ),
      ),
    );
  }
}
