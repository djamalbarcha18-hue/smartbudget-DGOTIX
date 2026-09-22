import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/category_bar_chart.dart';
import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/dashboard/application/dashboard_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Expense breakdown with a donut and a category bar chart that share ONE
/// selection state ([_selected]). Clean by default — no numbers are printed on
/// the marks; the amount and share of a category are revealed only when the
/// user hovers, taps or focuses it in either chart, and the two stay in sync.
class ExpenseBreakdownSection extends ConsumerStatefulWidget {
  const ExpenseBreakdownSection({super.key});

  @override
  ConsumerState<ExpenseBreakdownSection> createState() =>
      _ExpenseBreakdownSectionState();
}

class _ExpenseBreakdownSectionState
    extends ConsumerState<ExpenseBreakdownSection> {
  /// The shared selected category index (into the aggregated segment list), or
  /// null when nothing is selected. This is the single source of truth for both
  /// the donut and the bar chart.
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<CategoryTotal> totals =
        ref.watch(scopedExpenseCategoryTotalsProvider);

    // Aggregate to top 6 + "Other" — identical rule to the income donut.
    final int grandTotal =
        totals.fold<int>(0, (int s, CategoryTotal t) => s + t.amount.minorUnits);
    final List<DonutSegment> segments = <DonutSegment>[];
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
          valueLabel: MoneyFormatter.format(top[i].amount),
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
          valueLabel: MoneyFormatter.format(Money(otherMinor, currency)),
        ));
      }
    }

    // Keep the selection valid if the data shrank.
    final int? selected =
        (_selected != null && _selected! < segments.length) ? _selected : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DsSectionHeader(
                    title: l.sectionExpenseBreakdown,
                    icon: Icons.donut_small_outlined),
              ),
              if (selected != null)
                _ClearButton(onClear: () => setState(() => _selected = null)),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          if (segments.isEmpty)
            Expanded(
              child: Center(
                child: Text(l.emptyTransactionsMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
            )
          else ...<Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints cons) {
                  final Widget donut = Center(
                    child: DonutChart(
                      segments: segments,
                      size: 140,
                      thickness: 26,
                      centerTop: MoneyFormatter.compact(
                          Money(grandTotal, totals.first.amount.currencyCode)),
                      centerBottom: l.sectionExpenseBreakdown,
                      selectedIndex: selected,
                      onSelectionChanged: (int? i) =>
                          setState(() => _selected = i),
                    ),
                  );
                  final Widget bars = SingleChildScrollView(
                    child: CategoryBarChart(
                      segments: segments,
                      total: grandTotal.toDouble(),
                      selectedIndex: selected,
                      onSelectionChanged: (int? i) =>
                          setState(() => _selected = i),
                    ),
                  );

                  // Enough width → bars beside the donut; else stack them.
                  if (cons.maxWidth >= 380) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(width: 156, child: donut),
                        const SizedBox(width: DsSpacing.lg),
                        Expanded(child: bars),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      donut,
                      const SizedBox(height: DsSpacing.md),
                      Expanded(child: bars),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            _DetailStrip(
              segment: selected == null ? null : segments[selected],
              grandTotal: grandTotal.toDouble(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return TextButton.icon(
      onPressed: onClear,
      icon: Icon(Icons.close_rounded, size: 15, color: c.textMuted),
      label: Text(l.clearSelection,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: c.textMuted)),
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: DsSpacing.sm, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// The detail row under the charts: a neutral hint when nothing is selected,
/// or the selected category's name, amount and share of total expenses.
class _DetailStrip extends StatelessWidget {
  const _DetailStrip({
    required this.segment,
    required this.grandTotal,
  });

  final DonutSegment? segment;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    if (segment == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md, vertical: DsSpacing.sm),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: DsRadius.brSm,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.touch_app_outlined, size: 16, color: c.textFaint),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Text(l.breakdownHint,
                  style: t.labelSmall?.copyWith(color: c.textMuted)),
            ),
          ],
        ),
      );
    }

    final DonutSegment s = segment!;
    final int pct = grandTotal <= 0 ? 0 : (s.value / grandTotal * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md, vertical: DsSpacing.sm),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.10),
        borderRadius: DsRadius.brSm,
        border: Border.all(color: s.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: s.color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(s.label,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: DsSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(s.valueLabel ?? '',
                  style:
                      t.titleSmall?.copyWith(color: s.color, fontWeight: FontWeight.w700)),
              Text(l.ofTotalExpenses(pct),
                  style: t.labelSmall?.copyWith(color: c.textFaint)),
            ],
          ),
        ],
      ),
    );
  }
}
