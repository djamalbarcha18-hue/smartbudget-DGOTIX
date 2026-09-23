import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/savings_jar_icon.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/analytics/application/alerts_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/salary_split/presentation/salary_split_card.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Monthly Budget: one screen with year + month selectors — not 12 pages.
class MonthlyBudgetPage extends ConsumerWidget {
  const MonthlyBudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final FinanceSummary summary = ref.watch(monthlySummaryProvider);
    final List<Transaction> monthTxns = ref.watch(monthTransactionsProvider);
    final bool hasData = summary.count > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.pageMonthlyBudget,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.xl),
          Wrap(
            spacing: DsSpacing.gridGap,
            runSpacing: DsSpacing.gridGap,
            children: <Widget>[
              _kpi(l.kpiTotalIncome, hasData ? MoneyFormatter.format(summary.income) : null, c.income, Icons.south_west_outlined),
              _kpi(l.kpiTotalExpenses, hasData ? MoneyFormatter.format(summary.expense) : null, c.expense, Icons.north_east_outlined),
              _kpi(l.kpiNetProfit, hasData ? MoneyFormatter.format(summary.net) : null, c.net, null, iconChild: const SavingsJarGlyph()),
              _kpi(l.kpiSavingsRate, hasData ? MoneyFormatter.percent(summary.savingsRate) : null, c.saving, null, iconChild: const SavingsJarGlyph()),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),
          const SalarySplitCard(),
          const SizedBox(height: DsSpacing.lg),
          const _BudgetSection(),
          const SizedBox(height: DsSpacing.xxl),
          Text(l.monthTransactions,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DsSpacing.md),
          if (monthTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.xxl),
              child: Center(
                child: Text(l.emptyTransactionsMessage,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthTxns.length,
              separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.sm),
              itemBuilder: (BuildContext context, int i) =>
                  TransactionTile(txn: monthTxns[i]),
            ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String? value, Color accent, IconData? icon,
          {Widget? iconChild}) =>
      SizedBox(
        width: 220,
        child: KpiCard(
            label: label,
            value: value,
            accent: accent,
            icon: icon,
            iconChild: iconChild),
      );
}

/// Planned (budget) vs actual per expense category for the selected month.
class _BudgetSection extends ConsumerWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currency = ref.watch(baseCurrencyProvider);
    final Map<String, Money> planned =
        ref.watch(monthPlannedByCategoryProvider);
    final List<CategoryTotal> actualList =
        ref.watch(monthExpenseCategoryTotalsProvider);
    final Map<String, int> actual = <String, int>{
      for (final CategoryTotal t in actualList) t.category: t.amount.minorUnits,
    };
    final AlertFocus? focus = ref.watch(alertFocusProvider);
    final String? focusCategory =
        (focus != null && focus.route == '/budget') ? focus.key : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.plannedVsActual,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DsSpacing.xs),
          Text(l.plannedVsActualHint,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: DsSpacing.lg),
          for (final String cat
              in ref.watch(categoriesForProvider(TransactionType.expense)))
            _BudgetRow(
              category: cat,
              plannedMinor: planned[cat]?.minorUnits ?? 0,
              actualMinor: actual[cat] ?? 0,
              currency: currency,
              highlighted: focusCategory == cat,
            ),
        ],
      ),
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({
    required this.category,
    required this.plannedMinor,
    required this.actualMinor,
    required this.currency,
    this.highlighted = false,
  });

  final String category;
  final int plannedMinor;
  final int actualMinor;
  final String currency;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool over = plannedMinor > 0 && actualMinor > plannedMinor;
    final double fraction =
        plannedMinor == 0 ? 0 : actualMinor / plannedMinor;
    final String catLabel = Catalog.label(category,
        ar: Localizations.localeOf(context).languageCode == 'ar');

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: highlighted
            ? const EdgeInsets.all(DsSpacing.sm)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: highlighted ? c.brand.withValues(alpha: 0.08) : null,
          borderRadius: DsRadius.brMd,
          border: highlighted
              ? Border.all(color: c.brand.withValues(alpha: 0.6))
              : null,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(catLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                MoneyFormatter.format(Money(actualMinor, currency)),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: over ? c.expense : c.textPrimary,
                    ),
              ),
              Text('  /  ', style: Theme.of(context).textTheme.labelSmall),
              InkWell(
                onTap: () => _setPlanned(context, ref, l),
                borderRadius: DsRadius.brSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        plannedMinor == 0
                            ? l.setBudget
                            : MoneyFormatter.format(
                                Money(plannedMinor, currency)),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: c.brand,
                            ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.edit_outlined, size: 13, color: c.brand),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: plannedMinor == 0 ? 0 : fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? c.expense : c.saving,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _setPlanned(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final TextEditingController ctrl = TextEditingController(
      text: plannedMinor == 0
          ? ''
          : Money(plannedMinor, currency).asDouble.toString(),
    );
    final int year = ref.read(selectedYearProvider);
    final int month = ref.read(selectedMonthProvider);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${l.setBudget} · ${Catalog.label(category, ar: Localizations.localeOf(context).languageCode == 'ar')}'),
        content: TextField(
          controller: ctrl,
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
          double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
      await ref.read(budgetActionsProvider).setPlanned(
            year: year,
            month: month,
            category: category,
            amount: n,
          );
    }
    ctrl.dispose();
  }
}
