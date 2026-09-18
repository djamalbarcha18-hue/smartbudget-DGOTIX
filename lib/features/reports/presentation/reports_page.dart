import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/kpi_card.dart';
import 'package:smartbudget/design_system/components/savings_jar_icon.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/reports/application/reports_controller.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final ReportPeriod period = ref.watch(selectedReportPeriodProvider);
    final int sub = ref.watch(selectedReportSubProvider);
    final int year = ref.watch(selectedYearProvider);
    final ReportResult report = ref.watch(reportResultProvider);
    final bool hasData = report.summary.count > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandedTitle(l.brandAnalytics,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DsSpacing.lg),

          // Controls.
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _Box(
                child: DropdownButton<ReportPeriod>(
                  value: period,
                  underline: const SizedBox.shrink(),
                  dropdownColor: c.bgElevated,
                  items: <DropdownMenuItem<ReportPeriod>>[
                    for (final ReportPeriod p in ReportPeriod.values)
                      DropdownMenuItem<ReportPeriod>(
                          value: p, child: Text(_periodLabel(p, l))),
                  ],
                  onChanged: (ReportPeriod? p) {
                    if (p == null) return;
                    ref.read(selectedReportPeriodProvider.notifier).state = p;
                    ref.read(selectedReportSubProvider.notifier).state =
                        ReportPeriods.defaultSub(p, DateTime.now());
                  },
                ),
              ),
              if (period != ReportPeriod.yearly)
                _Box(
                  child: DropdownButton<int>(
                    value: sub,
                    underline: const SizedBox.shrink(),
                    dropdownColor: c.bgElevated,
                    items: <DropdownMenuItem<int>>[
                      for (int s = 1; s <= ReportPeriods.subCount(period); s++)
                        DropdownMenuItem<int>(
                            value: s, child: Text(_subLabel(context, period, s, l))),
                    ],
                    onChanged: (int? s) => s == null
                        ? null
                        : ref.read(selectedReportSubProvider.notifier).state = s,
                  ),
                ),
              _Box(
                child: DropdownButton<int>(
                  value: year,
                  underline: const SizedBox.shrink(),
                  dropdownColor: c.bgElevated,
                  items: <DropdownMenuItem<int>>[
                    // Current year and the next nine (e.g. 2026–2035).
                    for (int y = DateTime.now().year;
                        y <= DateTime.now().year + 9;
                        y++)
                      DropdownMenuItem<int>(value: y, child: Text('$y')),
                  ],
                  onChanged: (int? y) => y == null
                      ? null
                      : ref.read(selectedYearProvider.notifier).state = y,
                ),
              ),
              TextButton.icon(
                onPressed: null, // architecture-ready; wired in a later phase
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(l.exportPdfSoon),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xl),

          Wrap(
            spacing: DsSpacing.gridGap,
            runSpacing: DsSpacing.gridGap,
            children: <Widget>[
              _kpi(l.kpiTotalIncome, hasData ? MoneyFormatter.format(report.summary.income) : null, c.income, Icons.south_west_outlined),
              _kpi(l.kpiTotalExpenses, hasData ? MoneyFormatter.format(report.summary.expense) : null, c.expense, Icons.north_east_outlined),
              _kpi(l.kpiNetProfit, hasData ? MoneyFormatter.format(report.summary.net) : null, c.net, null, iconChild: const SavingsJarGlyph()),
              _kpi(l.kpiSavingsRate, hasData ? MoneyFormatter.percent(report.summary.savingsRate) : null, c.saving, null, iconChild: const SavingsJarGlyph()),
            ],
          ),
          const SizedBox(height: DsSpacing.xxl),

          _MonthlyTrendCard(points: ref.watch(reportMonthlyTrendProvider)),
          const SizedBox(height: DsSpacing.lg),

          _CategoryCard(
            title: l.reportIncomeByCategory,
            totals: report.incomeCategories,
            color: c.income,
          ),
          const SizedBox(height: DsSpacing.lg),
          _CategoryCard(
            title: l.reportExpenseByCategory,
            totals: report.expenseCategories,
            color: c.expense,
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

  String _periodLabel(ReportPeriod p, AppLocalizations l) => switch (p) {
        ReportPeriod.monthly => l.periodMonthly,
        ReportPeriod.quarterly => l.periodQuarterly,
        ReportPeriod.halfYearly => l.periodHalfYearly,
        ReportPeriod.yearly => l.periodYearly,
      };

  String _subLabel(
      BuildContext context, ReportPeriod p, int s, AppLocalizations l) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    switch (p) {
      case ReportPeriod.monthly:
        const List<String> arM = <String>[
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];
        const List<String> enM = <String>[
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
        return (ar ? arM : enM)[s - 1];
      case ReportPeriod.quarterly:
        return ar ? 'الربع $s' : 'Q$s';
      case ReportPeriod.halfYearly:
        return s == 2 ? l.half2 : l.half1;
      case ReportPeriod.yearly:
        return '';
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.totals,
    required this.color,
  });

  final String title;
  final List<CategoryTotal> totals;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final int max = totals.isEmpty ? 0 : totals.first.amount.minorUnits;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DsSpacing.lg),
          if (totals.isEmpty)
            Text(l.emptyTransactionsMessage,
                style: Theme.of(context).textTheme.bodySmall)
          else
            for (final CategoryTotal t in totals)
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                              Catalog.label(t.category,
                                  ar: Localizations.localeOf(context)
                                          .languageCode ==
                                      'ar'),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(MoneyFormatter.format(t.amount),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: c.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: max == 0
                            ? 0
                            : (t.amount.minorUnits / max).clamp(0.02, 1.0),
                        minHeight: 7,
                        backgroundColor: c.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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

/// Grouped income-vs-expense bars across the 12 months of the selected year.
class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.points});

  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final int maxMinor = points.fold<int>(0, (int m, MonthPoint p) {
      final int hi = p.income.minorUnits > p.expense.minorUnits
          ? p.income.minorUnits
          : p.expense.minorUnits;
      return hi > m ? hi : m;
    });

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(l.reportMonthlyTrend,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _LegendDot(color: c.income, label: l.legendIncome),
              const SizedBox(width: DsSpacing.md),
              _LegendDot(color: c.expense, label: l.legendExpenses),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          if (maxMinor == 0)
            Text(l.emptyTransactionsMessage,
                style: Theme.of(context).textTheme.bodySmall)
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: _TrendPainter(
                  points: points,
                  maxMinor: maxMinor,
                  income: c.income,
                  expense: c.expense,
                  axis: c.textFaint,
                  grid: c.border,
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

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.maxMinor,
    required this.income,
    required this.expense,
    required this.axis,
    required this.grid,
  });

  final List<MonthPoint> points;
  final int maxMinor;
  final Color income;
  final Color expense;
  final Color axis;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    const double labelBand = 18; // room for month numbers under the baseline
    final double chartH = size.height - labelBand;
    final double baseY = chartH;
    final double groupW = size.width / points.length;
    final double barW = (groupW * 0.30).clamp(3.0, 14.0);
    const double gap = 2;

    // Baseline.
    final Paint base = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), base);

    final Paint incPaint = Paint()..color = income;
    final Paint expPaint = Paint()..color = expense;

    for (int i = 0; i < points.length; i++) {
      final MonthPoint p = points[i];
      final double centre = groupW * i + groupW / 2;
      final double incH =
          maxMinor == 0 ? 0 : (p.income.minorUnits / maxMinor) * (chartH - 4);
      final double expH =
          maxMinor == 0 ? 0 : (p.expense.minorUnits / maxMinor) * (chartH - 4);

      final double incLeft = centre - barW - gap / 2;
      final double expLeft = centre + gap / 2;
      const Radius r = Radius.circular(2);

      if (incH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(incLeft, baseY - incH, barW, incH),
            topLeft: r,
            topRight: r,
          ),
          incPaint,
        );
      }
      if (expH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(expLeft, baseY - expH, barW, expH),
            topLeft: r,
            topRight: r,
          ),
          expPaint,
        );
      }

      // Month number label.
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(color: axis, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(centre - tp.width / 2, baseY + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points ||
      old.maxMinor != maxMinor ||
      old.income != income ||
      old.expense != expense;
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}
