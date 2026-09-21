import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/monthly_bars_chart.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/savings_jar_icon.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/analytics/domain/kpi_math.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/dashboard/presentation/dgotix_insights_section.dart';
import 'package:smartbudget/features/dashboard/presentation/global_markets_section.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Live dashboard: KPIs and breakdowns computed from the user's transactions
/// via [FinanceCalculator] (the SmartBudget rules). With no data, tiles show a
/// neutral empty state ("—") — never a fabricated number.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String? name = ref.watch(authControllerProvider).user?.name;
    final FinanceSummary summary = ref.watch(financeSummaryProvider);
    final bool hasData = summary.count > 0;

    // Period-over-period comparison (selected year vs the previous year).
    final FinanceSummary prev = ref.watch(previousYearSummaryProvider);
    final bool hasPrev = prev.count > 0;
    final KpiChange incomeChange = KpiChange.of(
        current: summary.income.minorUnits,
        previous: prev.income.minorUnits,
        hasPrevious: hasPrev);
    final KpiChange expenseChange = KpiChange.of(
        current: summary.expense.minorUnits,
        previous: prev.expense.minorUnits,
        hasPrevious: hasPrev);
    final KpiChange netChange = KpiChange.of(
        current: summary.net.minorUnits,
        previous: prev.net.minorUnits,
        hasPrevious: hasPrev);
    final String? vsPrev = hasPrev ? l.vsPreviousYear : null;

    final String greeting =
        name == null ? l.welcomeGreeting : '${l.welcomeGreeting}، $name';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(greeting: greeting),
          const SizedBox(height: DsSpacing.xl),

          // ---- Overview KPIs (real values, or "—" when empty) ----
          DsSectionHeader(title: l.sectionOverview, icon: Icons.pie_chart_outline),
          const SizedBox(height: DsSpacing.md),
          _ResponsiveGrid(
            minTileWidth: 240,
            children: <Widget>[
              KpiCard(
                label: l.kpiTotalIncome,
                value: hasData ? MoneyFormatter.format(summary.income) : null,
                icon: Icons.south_west_outlined,
                accent: c.income,
                delta: hasData
                    ? _pctDelta(context, incomeChange, positiveWhenUp: true)
                    : null,
                caption: hasData ? vsPrev : null,
              ),
              KpiCard(
                label: l.kpiTotalExpenses,
                value: hasData ? MoneyFormatter.format(summary.expense) : null,
                icon: Icons.north_east_outlined,
                accent: c.expense,
                delta: hasData
                    ? _pctDelta(context, expenseChange, positiveWhenUp: false)
                    : null,
                caption: hasData ? vsPrev : null,
              ),
              KpiCard(
                label: l.kpiNetProfit,
                value: hasData ? MoneyFormatter.format(summary.net) : null,
                iconChild: const SavingsJarGlyph(),
                accent: c.net,
                delta: hasData
                    ? _pctDelta(context, netChange, positiveWhenUp: true)
                    : null,
                caption: hasData ? vsPrev : null,
              ),
              KpiCard(
                label: l.kpiSavingsRate,
                value: hasData
                    ? MoneyFormatter.percent(summary.savingsRate)
                    : null,
                iconChild: const SavingsJarGlyph(),
                accent: c.saving,
                delta: hasData
                    ? _pointsDelta(
                        context, summary.savingsRate, prev.savingsRate, hasPrev)
                    : null,
                caption: hasData ? vsPrev : null,
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Financial health score (tap to open the full page) ----
          const _HealthHeroCard(),
          const SizedBox(height: DsSpacing.xxl),

          // ---- DGOTIX AI insights (top on-device analyses) ----
          const DgotixInsightsSection(),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Global markets (live, from keyless public sources) ----
          const GlobalMarketsSection(),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Monthly comparison: income vs expense bars + savings line ----
          DsSectionHeader(
              title: l.sectionMonthlyComparison,
              icon: Icons.bar_chart_rounded),
          const SizedBox(height: DsSpacing.md),
          const _MonthlyComparisonCard(),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Income & expense distribution (donuts) + recent ----
          _ResponsiveGrid(
            minTileWidth: 320,
            childAspectRatio: 0.92,
            children: <Widget>[
              const _IncomeDonutCard(),
              const _ExpenseDonutCard(),
              const _RecentTransactionsCard(),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Later-phase modules (kept as placeholders) ----
          _ResponsiveGrid(
            minTileWidth: 340,
            childAspectRatio: 1.5,
            children: <Widget>[
              const _GoalsMiniCard(),
              const _DebtsMiniCard(),
              const _ZakatMiniCard(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formats a [KpiChange] as a semantic delta pill for a KPI card. Color comes
/// from the metric's meaning (positiveWhenUp), not the arrow.
KpiDelta _pctDelta(BuildContext context, KpiChange ch,
    {required bool positiveWhenUp}) {
  if (!ch.comparable) {
    return KpiDelta.noComparison(AppLocalizations.of(context).noComparison);
  }
  return KpiDelta(
    label: _signedPct(ch.percentage! * 100),
    trend: _trendOf(ch.direction),
    tone: _toneOf(ch.sentiment(positiveWhenUp: positiveWhenUp)),
  );
}

/// Savings-rate style delta: the change is in percentage POINTS (up is good).
KpiDelta _pointsDelta(
    BuildContext context, double current, double previous, bool hasPrev) {
  if (!hasPrev) {
    return KpiDelta.noComparison(AppLocalizations.of(context).noComparison);
  }
  final double pts = (current - previous) * 100;
  return KpiDelta(
    label: _signedPct(pts),
    trend: pts > 0 ? KpiTrend.up : (pts < 0 ? KpiTrend.down : KpiTrend.flat),
    tone: pts > 0 ? KpiTone.good : (pts < 0 ? KpiTone.bad : KpiTone.neutral),
  );
}

String _signedPct(double v) {
  final String sign = v > 0 ? '+' : (v < 0 ? '−' : '');
  return '$sign${v.abs().toStringAsFixed(1)}%';
}

KpiTrend _trendOf(KpiDirection d) => switch (d) {
      KpiDirection.up => KpiTrend.up,
      KpiDirection.down => KpiTrend.down,
      KpiDirection.flat => KpiTrend.flat,
    };

KpiTone _toneOf(KpiSentiment s) => switch (s) {
      KpiSentiment.good => KpiTone.good,
      KpiSentiment.bad => KpiTone.bad,
      KpiSentiment.neutral => KpiTone.neutral,
    };

class _Header extends StatelessWidget {
  const _Header({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isMobile = context.isMobile;

    final List<Widget> actions = <Widget>[
      DsButton(
        label: l.addIncome,
        icon: Icons.south_west_rounded,
        variant: DsButtonVariant.secondary,
        onPressed: () => TransactionEditorSheet.show(context,
            type: TransactionType.income),
      ),
      DsButton(
        label: l.addExpense,
        icon: Icons.north_east_rounded,
        onPressed: () => TransactionEditorSheet.show(context,
            type: TransactionType.expense),
      ),
    ];

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandedTitle(
          l.brandInsights,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.dsColors.textMuted,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 2),
        Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          titleBlock,
          const SizedBox(height: DsSpacing.md),
          Wrap(spacing: DsSpacing.sm, runSpacing: DsSpacing.sm, children: actions),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: titleBlock),
        actions[0],
        const SizedBox(width: DsSpacing.sm),
        actions[1],
      ],
    );
  }
}

/// Monthly income vs expense bars with a savings (net) line overlay.
class _MonthlyComparisonCard extends ConsumerWidget {
  const _MonthlyComparisonCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final List<MonthPoint> points = ref.watch(monthlyTrendProvider);
    final bool hasData = points.any((MonthPoint p) =>
        p.income.minorUnits > 0 || p.expense.minorUnits > 0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: DsSpacing.lg,
            runSpacing: DsSpacing.xs,
            children: <Widget>[
              _LegendDot(color: c.income, label: l.legendIncome),
              _LegendDot(color: c.expense, label: l.legendExpenses),
              _LegendDot(color: c.net, label: l.legendNet),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.xl),
              child: Text(l.emptyTransactionsMessage,
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else
            MonthlyBarsChart(
              points: points,
              income: c.income,
              expense: c.expense,
              net: c.net,
              axis: c.textFaint,
              grid: c.border,
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _IncomeDonutCard extends ConsumerWidget {
  const _IncomeDonutCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DistributionBody(
      title: AppLocalizations.of(context).sectionIncomeDistribution,
      totals: ref.watch(incomeCategoryTotalsProvider),
    );
  }
}

class _ExpenseDonutCard extends ConsumerWidget {
  const _ExpenseDonutCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DistributionBody(
      title: AppLocalizations.of(context).sectionExpenseDistribution,
      totals: ref.watch(expenseCategoryTotalsProvider),
    );
  }
}

/// A donut of category shares (top 6 + aggregated "Other") with a legend.
class _DistributionBody extends StatelessWidget {
  const _DistributionBody({required this.title, required this.totals});
  final String title;
  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final int totalMinor =
        totals.fold<int>(0, (int s, CategoryTotal t) => s + t.amount.minorUnits);

    final List<DonutSegment> segments = <DonutSegment>[];
    final List<Widget> legend = <Widget>[];
    if (totals.isNotEmpty) {
      const int topN = 6;
      final List<CategoryTotal> top =
          totals.length > topN ? totals.sublist(0, topN) : totals;
      for (int i = 0; i < top.length; i++) {
        segments.add(DonutSegment(
          label: Catalog.label(top[i].category, ar: ar),
          value: top[i].amount.minorUnits.toDouble(),
          color: DsChartPalette.at(i),
        ));
      }
      if (totals.length > topN) {
        final int otherMinor = totals
            .sublist(topN)
            .fold<int>(0, (int s, CategoryTotal t) => s + t.amount.minorUnits);
        segments.add(DonutSegment(
          label: l.chartOther,
          value: otherMinor.toDouble(),
          color: DsChartPalette.other,
        ));
      }
      for (final DonutSegment seg in segments) {
        final int pct =
            totalMinor == 0 ? 0 : (seg.value / totalMinor * 100).round();
        legend.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: seg.color,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(seg.label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$pct%',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.textMuted)),
            ],
          ),
        ));
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(title: title, icon: Icons.donut_small_outlined),
          const SizedBox(height: DsSpacing.md),
          if (totals.isEmpty)
            Expanded(
              child: Center(
                child: Text(l.emptyTransactionsMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
            )
          else
            Expanded(
              child: Column(
                children: <Widget>[
                  Center(
                    child: DonutChart(
                      segments: segments,
                      centerTop: MoneyFormatter.compact(
                          Money(totalMinor, totals.first.amount.currencyCode)),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Expanded(child: ListView(children: legend)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends ConsumerWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Transaction> all =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final List<Transaction> recent = all.take(5).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(
            title: l.recentTransactions,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: DsSpacing.md),
          if (recent.isEmpty)
            Expanded(
              child: Center(
                child: Text(l.emptyTransactionsMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: recent.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DsSpacing.sm),
                itemBuilder: (BuildContext context, int i) =>
                    TransactionTile(txn: recent[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tappable dashboard summary card: header + a big value + caption, linking
/// to the full section. Reuses figures the feature engines already computed.
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.title,
    required this.icon,
    required this.route,
    required this.value,
    required this.caption,
    this.valueColor,
    this.progress,
  });

  final String title;
  final IconData icon;
  final String route;
  final String value;
  final String caption;
  final Color? valueColor;
  final double? progress; // 0..1 optional progress bar

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return GlassCard(
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => context.go(route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DsSectionHeader(title: title, icon: icon),
            const SizedBox(height: DsSpacing.md),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: valueColor ?? c.textPrimary)),
            const SizedBox(height: DsSpacing.xxs),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            if (progress != null) ...<Widget>[
              const SizedBox(height: DsSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: c.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(c.brand),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Prominent, tappable Financial Health score at the top of the dashboard.
/// A circular gauge + status, colored by health, that opens the full page.
class _HealthHeroCard extends ConsumerWidget {
  const _HealthHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool hasData = ref.watch(healthHasDataProvider);
    final HealthResult r = ref.watch(healthResultProvider);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    final (String, Color) meta = switch (r.status) {
      HealthStatus.excellent => (l.healthStatusExcellent, c.income),
      HealthStatus.veryGood => (l.healthStatusVeryGood, c.income),
      HealthStatus.good => (l.healthStatusGood, c.brand),
      HealthStatus.fair => (l.healthStatusFair, c.saving),
      HealthStatus.needsWork => (l.healthStatusNeedsWork, c.expense),
    };
    final Color tone = hasData ? meta.$2 : c.textMuted;

    return GlassCard(
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => context.go('/health'),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      value: hasData ? (r.score.clamp(0, 100) / 100) : 0,
                      strokeWidth: 6,
                      backgroundColor: c.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(tone),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(hasData ? '${r.score.round()}' : '—',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: tone, fontWeight: FontWeight.w800)),
                      Text('/100',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: c.textFaint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.monitor_heart_outlined, size: 18, color: tone),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Text(l.sectionFinancialHealth,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(
                    hasData ? meta.$1 : l.healthEmpty,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: hasData ? tone : c.textMuted),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(l.viewDetails,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: c.textFaint)),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Icon(
              rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: c.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsMiniCard extends ConsumerWidget {
  const _GoalsMiniCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Goal> goals =
        ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    int saved = 0;
    int target = 0;
    for (final Goal g in goals) {
      saved += g.saved.minorUnits;
      target += g.target.minorUnits;
    }
    final double pct = target > 0 ? saved / target : 0;
    return _MiniCard(
      title: l.sectionGoals,
      icon: Icons.flag_outlined,
      route: '/goals',
      value: goals.isEmpty ? '—' : '${(pct * 100).round()}%',
      caption: goals.isEmpty
          ? l.emptyGoalsTitle
          : '${goals.length} · ${l.goalSaved}',
      progress: goals.isEmpty ? null : pct,
    );
  }
}

class _DebtsMiniCard extends ConsumerWidget {
  const _DebtsMiniCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final DebtSummary s = ref.watch(debtSummaryProvider);
    final bool positive = s.net.minorUnits >= 0;
    return _MiniCard(
      title: l.sectionDebts,
      icon: Icons.account_balance_outlined,
      route: '/debts',
      value: MoneyFormatter.format(s.net),
      valueColor: positive ? c.income : c.expense,
      caption: '${l.debtNet} · ${s.openCount}',
    );
  }
}

class _ZakatMiniCard extends ConsumerWidget {
  const _ZakatMiniCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final zakat = ref.watch(zakatResultProvider);
    return _MiniCard(
      title: l.sectionZakat,
      icon: Icons.mosque_outlined,
      route: '/zakat',
      value: zakat.obligatory ? MoneyFormatter.format(zakat.due) : '—',
      valueColor: zakat.obligatory ? c.saving : null,
      caption: zakat.obligatory ? l.zakatObligatory : l.zakatNotDue,
    );
  }
}

/// Overflow-safe responsive grid (columns computed from available width).
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    required this.minTileWidth,
    this.childAspectRatio,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = DsSpacing.gridGap;
        final double maxW = constraints.maxWidth;
        int cols = (maxW / (minTileWidth + gap)).floor().clamp(1, 4).toInt();
        if (context.isMobile) cols = 1;
        final double tileW = (maxW - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (Widget child) => SizedBox(
                  width: tileW,
                  height:
                      childAspectRatio != null ? tileW / childAspectRatio! : null,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
