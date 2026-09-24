import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:smartbudget/core/l10n/month_names.dart';
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
import 'package:smartbudget/design_system/tokens/ds_typography.dart';
import 'package:smartbudget/features/analytics/domain/kpi_math.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/presentation/backup_reminder_card.dart';
import 'package:smartbudget/features/dashboard/application/dashboard_controller.dart';
import 'package:smartbudget/features/dashboard/presentation/dashboard_cards.dart';
import 'package:smartbudget/features/dashboard/presentation/dgotix_insights_section.dart';
import 'package:smartbudget/features/dashboard/presentation/expense_breakdown_section.dart';
import 'package:smartbudget/features/dashboard/presentation/global_markets_section.dart';
import 'package:smartbudget/features/onboarding/presentation/welcome_card.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
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
    final DashboardScope scope = ref.watch(dashboardScopeProvider);
    final FinanceSummary summary = ref.watch(scopedSummaryProvider);
    final bool hasData = summary.count > 0;

    // Period-over-period comparison (previous month, or previous year).
    final FinanceSummary prev = ref.watch(scopedPreviousSummaryProvider);
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
    final String? vsPrev = hasPrev
        ? (scope == DashboardScope.month ? l.vsPreviousMonth : l.vsPreviousYear)
        : null;

    final String greeting =
        name == null ? l.welcomeGreeting : '${l.welcomeGreeting}، $name';

    // KPI cards, highest priority first ("what's left" leads — it's the
    // question users open a budgeting app to answer).
    final List<Widget> kpis = <Widget>[
      KpiCard(
        label: l.kpiNetProfit,
        value: hasData ? MoneyFormatter.format(summary.net) : null,
        iconChild: const SavingsJarGlyph(),
        delta: hasData
            ? _pctDelta(context, netChange, positiveWhenUp: true)
            : null,
        caption: hasData ? vsPrev : null,
      ),
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
        label: l.kpiSavingsRate,
        value: hasData ? MoneyFormatter.percent(summary.savingsRate) : null,
        iconChild: const SavingsJarGlyph(),
        delta: hasData
            ? _pointsDelta(
                context, summary.savingsRate, prev.savingsRate, hasPrev)
            : null,
        caption: hasData ? vsPrev : null,
      ),
    ];

    const double gap = DsSpacing.gridGap;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(greeting: greeting, scope: scope),
          const SizedBox(height: DsSpacing.xl),
          const WelcomeCard(),
          const BackupReminderCard(),

          // ① The four headline figures, one uniform row.
          _ResponsiveGrid(minTileWidth: 220, children: kpis),
          const SizedBox(height: gap),

          // ② Month pulse: budget used · health score · what's due soon.
          const _EqualRow(
            height: 150,
            children: <Widget>[
              BudgetPulseCard(),
              HealthPulseCard(),
              UpcomingPulseCard(),
            ],
          ),
          const SizedBox(height: gap),

          // ③ Every analysis row is a main panel (8/12) and a companion
          //    (4/12) of the same height, so nothing leaves a gap.
          const _PanelRow(
            height: 380,
            main: _MonthlyComparisonCard(),
            side: AlertsPanel(),
            sideNarrowHeight: 300,
          ),
          const SizedBox(height: gap),
          const _PanelRow(
            height: 400,
            main: ExpenseBreakdownSection(),
            mainNarrowHeight: 440,
            side: _IncomeDonutCard(),
            sideNarrowHeight: 340,
          ),
          const SizedBox(height: gap),
          const _PanelRow(
            height: 392,
            main: _RecentTransactionsCard(),
            side: PlansCard(),
            sideNarrowHeight: 300,
          ),
          const SizedBox(height: gap),

          // ④ DGOTIX AI insights, then live global markets at the bottom.
          const DgotixInsightsSection(),
          const SizedBox(height: gap),
          const GlobalMarketsSection(),
        ],
      ),
    );
  }
}

/// Compact month/year period switcher for the dashboard overview.
class _ScopeToggle extends ConsumerWidget {
  const _ScopeToggle({required this.scope});
  final DashboardScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    Widget seg(String label, DashboardScope value) {
      final bool sel = scope == value;
      return GestureDetector(
        onTap: () =>
            ref.read(dashboardScopeProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? c.brand : Colors.transparent,
            borderRadius: DsRadius.brPill,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: sel ? c.onBrand : c.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brPill,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          seg(l.scopeMonth, DashboardScope.month),
          seg(l.scopeYear, DashboardScope.year),
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
  const _Header({required this.greeting, required this.scope});
  final String greeting;
  final DashboardScope scope;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isMobile = context.isMobile;

    final List<Widget> actions = <Widget>[
      _ScopeToggle(scope: scope),
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
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: titleBlock),
        for (final Widget a in actions) ...<Widget>[
          const SizedBox(width: DsSpacing.sm),
          a,
        ],
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

    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final Widget legend = Wrap(
      spacing: DsSpacing.lg,
      runSpacing: DsSpacing.xs,
      children: <Widget>[
        _LegendDot(color: c.income, label: l.legendIncome),
        _LegendDot(color: c.expense, label: l.legendExpenses),
        _LegendDot(color: c.brand, label: l.legendNet),
      ],
    );
    final Widget header = DsSectionHeader(
        title: l.sectionMonthlyComparison, icon: Icons.bar_chart_rounded);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints cons) =>
                cons.maxWidth >= 560
                    ? Row(children: <Widget>[
                        Expanded(child: header),
                        const SizedBox(width: DsSpacing.md),
                        legend,
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          header,
                          const SizedBox(height: DsSpacing.sm),
                          legend,
                        ],
                      ),
          ),
          const SizedBox(height: DsSpacing.lg),
          Expanded(
            child: !hasData
                ? Center(
                    child: Text(l.emptyTransactionsMessage,
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints cons) =>
                        MonthlyBarsChart(
                      points: points,
                      income: c.income,
                      expense: c.expense,
                      net: c.brand,
                      axis: c.textFaint,
                      grid: c.border,
                      height: cons.maxHeight,
                      monthLabels: MonthNames.short(ar: ar),
                    ),
                  ),
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
      totals: ref.watch(scopedIncomeCategoryTotalsProvider),
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
      final String currency = totals.first.amount.currencyCode;
      for (int i = 0; i < top.length; i++) {
        segments.add(DonutSegment(
          label: Catalog.label(top[i].category, ar: ar),
          value: top[i].amount.minorUnits.toDouble(),
          color: DsChartPalette.at(i),
          valueLabel: MoneyFormatter.compact(top[i].amount),
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
          valueLabel: MoneyFormatter.compact(Money(otherMinor, currency)),
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
                      size: 168,
                      thickness: 30,
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
    final DsColors c = context.dsColors;
    final List<Transaction> all =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final List<Transaction> recent = all.take(5).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsSectionHeader(
            title: l.recentTransactions,
            icon: Icons.receipt_long_outlined,
            trailing: recent.isEmpty
                ? null
                : TextButton(
                    onPressed: () => context.go('/transactions'),
                    style: TextButton.styleFrom(foregroundColor: c.brand),
                    child: Text(l.viewAll),
                  ),
          ),
          const SizedBox(height: DsSpacing.md),
          Expanded(
            child: recent.isEmpty
                ? Center(
                    child: Text(l.emptyTransactionsMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints cons) {
                      // Wide: a proper table. Narrow: the compact tiles.
                      if (cons.maxWidth >= 640) {
                        return SingleChildScrollView(
                            child: _TransactionsTable(txns: recent));
                      }
                      return ListView.separated(
                        itemCount: recent.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: DsSpacing.sm),
                        itemBuilder: (BuildContext context, int i) =>
                            TransactionTile(txn: recent[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Recent transactions as a table: date, type, category, description and
/// amount. Rows open the editor, like everywhere else transactions appear.
class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({required this.txns});
  final List<Transaction> txns;

  static const List<int> _flex = <int>[2, 2, 2, 4, 2];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final TextStyle? head =
        t.labelMedium?.copyWith(color: c.textFaint, fontWeight: FontWeight.w700);

    Widget cell(int i, Widget child, {bool end = false}) => Expanded(
          flex: _flex[i],
          child: Align(
            alignment: end
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: child,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: DsSpacing.sm),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: DsRadius.brMd,
          ),
          child: Row(
            children: <Widget>[
              cell(0, Text(l.fieldDate, style: head)),
              cell(1, Text(l.fieldType, style: head)),
              cell(2, Text(l.fieldCategory, style: head)),
              cell(3, Text(l.fieldDescription, style: head)),
              cell(4, Text(l.fieldAmount, style: head), end: true),
              const SizedBox(width: 28),
            ],
          ),
        ),
        for (int i = 0; i < txns.length; i++) ...<Widget>[
          if (i > 0) Divider(height: 1, color: c.border),
          _TableRow(txn: txns[i], cell: cell),
        ],
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.txn, required this.cell});
  final Transaction txn;
  final Widget Function(int i, Widget child, {bool end}) cell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Color tone = txn.isIncome ? c.income : c.expense;
    final String category = Catalog.label(txn.category, ar: ar);

    return InkWell(
      borderRadius: DsRadius.brMd,
      hoverColor: c.textPrimary.withValues(alpha: 0.04),
      onTap: () =>
          TransactionEditorSheet.show(context, type: txn.type, existing: txn),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.md),
        child: Row(
          children: <Widget>[
            cell(
              0,
              Text(DateFormat('yyyy-MM-dd').format(txn.date),
                  style: DsTypography.mono(t.bodySmall ?? const TextStyle())),
            ),
            cell(
              1,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: DsRadius.brPill,
                  border: Border.all(color: tone.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                        txn.isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 12,
                        color: tone),
                    const SizedBox(width: 4),
                    Text(txn.isIncome ? l.txnTypeIncome : l.txnTypeExpense,
                        style: t.labelSmall?.copyWith(
                            color: tone, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            cell(
              2,
              Text(category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: c.textPrimary)),
            ),
            cell(
              3,
              Row(
                children: <Widget>[
                  if (RecurrenceEngine.isRecurring(txn)) ...<Widget>[
                    Tooltip(
                      message: l.recurringBadge,
                      child: Icon(Icons.event_repeat_outlined,
                          size: 14, color: c.textFaint),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                        txn.description.isEmpty ? '—' : txn.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall),
                  ),
                ],
              ),
            ),
            cell(
              4,
              Text(
                '${txn.isIncome ? '+' : '−'} ${MoneyFormatter.format(txn.amount)}',
                style: DsTypography.mono(t.titleSmall ?? const TextStyle())
                    .copyWith(color: tone, fontWeight: FontWeight.w700),
              ),
              end: true,
            ),
            SizedBox(
              width: 28,
              child: Icon(
                  rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: c.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overflow-safe responsive grid (columns computed from available width).
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    required this.minTileWidth,
  });

  final List<Widget> children;
  final double minTileWidth;

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
                (Widget child) => SizedBox(width: tileW, child: child),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

/// A row of equal cards at a fixed height (wide screens); stacked on phones.
class _EqualRow extends StatelessWidget {
  const _EqualRow({required this.children, required this.height});
  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    const double gap = DsSpacing.gridGap;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints cons) {
        if (cons.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: gap),
                SizedBox(height: height, child: children[i]),
              ],
            ],
          );
        }
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The dashboard's analysis row: a main panel (8/12) beside a companion
/// (4/12) at one shared height on wide screens; stacked full-width below.
class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.main,
    required this.side,
    required this.height,
    this.mainNarrowHeight,
    this.sideNarrowHeight,
  });

  final Widget main;
  final Widget side;
  final double height;
  final double? mainNarrowHeight;
  final double? sideNarrowHeight;

  @override
  Widget build(BuildContext context) {
    const double gap = DsSpacing.gridGap;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints cons) {
        if (cons.maxWidth >= 1000) {
          return SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(flex: 8, child: main),
                const SizedBox(width: gap),
                Expanded(flex: 4, child: side),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: mainNarrowHeight ?? height, child: main),
            const SizedBox(height: gap),
            SizedBox(height: sideNarrowHeight ?? height, child: side),
          ],
        );
      },
    );
  }
}
