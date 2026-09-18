import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
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
    final FinanceSummary summary = ref.watch(financeSummaryProvider);
    final bool hasData = summary.count > 0;

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
              ),
              KpiCard(
                label: l.kpiTotalExpenses,
                value: hasData ? MoneyFormatter.format(summary.expense) : null,
                icon: Icons.north_east_outlined,
                accent: c.expense,
              ),
              KpiCard(
                label: l.kpiNetProfit,
                value: hasData ? MoneyFormatter.format(summary.net) : null,
                icon: Icons.savings_outlined,
                accent: c.net,
              ),
              KpiCard(
                label: l.kpiSavingsRate,
                value: hasData
                    ? MoneyFormatter.percent(summary.savingsRate)
                    : null,
                icon: Icons.percent_outlined,
                accent: c.saving,
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Expense distribution + recent transactions ----
          _ResponsiveGrid(
            minTileWidth: 340,
            childAspectRatio: 1.1,
            children: <Widget>[
              const _ExpenseDistributionCard(),
              const _RecentTransactionsCard(),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),

          // ---- Later-phase modules (kept as placeholders) ----
          _ResponsiveGrid(
            minTileWidth: 340,
            childAspectRatio: 1.5,
            children: <Widget>[
              _PlaceholderCard(title: l.sectionFinancialHealth, icon: Icons.monitor_heart_outlined),
              _PlaceholderCard(title: l.sectionGoals, icon: Icons.flag_outlined),
              _PlaceholderCard(title: l.sectionDebts, icon: Icons.account_balance_outlined),
              _PlaceholderCard(title: l.sectionZakat, icon: Icons.mosque_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.md),
          Wrap(spacing: DsSpacing.sm, runSpacing: DsSpacing.sm, children: actions),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
        ),
        actions[0],
        const SizedBox(width: DsSpacing.sm),
        actions[1],
      ],
    );
  }
}

class _ExpenseDistributionCard extends ConsumerWidget {
  const _ExpenseDistributionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final List<CategoryTotal> totals =
        ref.watch(expenseCategoryTotalsProvider);
    final int max = totals.isEmpty ? 0 : totals.first.amount.minorUnits;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(
            title: l.sectionExpenseDistribution,
            icon: Icons.donut_small_outlined,
          ),
          const SizedBox(height: DsSpacing.lg),
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
              child: ListView(
                children: <Widget>[
                  for (final CategoryTotal t in totals.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: DsSpacing.md),
                      child: _CategoryBar(
                        label: t.category,
                        amountText: MoneyFormatter.format(t.amount),
                        fraction: max == 0 ? 0 : t.amount.minorUnits / max,
                        color: c.expense,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.amountText,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String amountText;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(amountText,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: c.textPrimary,
                    )),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.02, 1.0),
            minHeight: 7,
            backgroundColor: c.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(title: title, icon: icon),
          const SizedBox(height: DsSpacing.lg),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.insights_outlined, size: 30, color: c.textFaint),
                  const SizedBox(height: DsSpacing.sm),
                  Text(l.comingSoon,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
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
