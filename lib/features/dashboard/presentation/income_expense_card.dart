import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_chart_palette.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/dashboard/application/dashboard_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Where the money came from and where it went, in one card: two tabs over
/// two pages (income first, from the reading side), swiped or tapped. Each
/// page is a donut with its categories beside it; tapping a category (or
/// its slice) shows its value in the donut, tapping again shows the total.
class IncomeExpenseCard extends ConsumerStatefulWidget {
  const IncomeExpenseCard({super.key});

  /// Tall enough for about five category rows and the "view all" line, the
  /// same on both pages so the card never jumps.
  static const double pageHeight = 196;

  @override
  ConsumerState<IncomeExpenseCard> createState() => _IncomeExpenseCardState();
}

class _IncomeExpenseCardState extends ConsumerState<IncomeExpenseCard> {
  final PageController _pages = PageController();
  int _page = 0;

  static const Duration _quick = Duration(milliseconds: 180);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _open(int i) {
    if (i == _page) return;
    setState(() => _page = i);
    _pages.animateToPage(i,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final Color accent = _page == 0 ? c.income : c.expense;
    final bool empty = ref
        .watch(_page == 0
            ? scopedIncomeCategoryTotalsProvider
            : scopedExpenseCategoryTotalsProvider)
        .isEmpty;

    return GlassCard(
      accent: accent,
      // On a wide screen the content keeps a phone-like width, centred, so
      // each share stays next to its category.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _TypeTab(
                      label: l.legendIncome,
                      icon: Icons.south_west_outlined,
                      color: c.income,
                      selected: _page == 0,
                      onTap: () => _open(0),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: _TypeTab(
                      label: l.legendExpenses,
                      icon: Icons.north_east_outlined,
                      color: c.expense,
                      selected: _page == 1,
                      onTap: () => _open(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              SizedBox(
                height: IncomeExpenseCard.pageHeight,
                // Follows the reading direction: income on the start side.
                child: ScrollConfiguration(
                  // A mouse can swipe it too (on the web, on a computer).
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (int i) => setState(() => _page = i),
                    children: const <Widget>[
                      _BreakdownPage(type: TransactionType.income),
                      _BreakdownPage(type: TransactionType.expense),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < 2; i++)
                    AnimatedContainer(
                      duration: _quick,
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? accent : c.borderStrong,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
              if (!empty) ...<Widget>[
                const SizedBox(height: DsSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.touch_app_outlined,
                        size: 14, color: c.textFaint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(l.breakdownHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: c.textMuted)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab marked three ways when chosen: filled in its colour with bold
/// white text, its arrow, and a line under it.
class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _quick = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color fill = readableFill(color);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: DsRadius.brMd,
          child: AnimatedContainer(
            duration: _quick,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? fill : c.surfaceMuted.withValues(alpha: 0.5),
              borderRadius: DsRadius.brMd,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.sm, vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(icon,
                          size: 16,
                          color: selected ? Colors.white : c.textFaint),
                      const SizedBox(width: 6),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: _quick,
                          style: (Theme.of(context).textTheme.labelLarge ??
                                  const TextStyle())
                              .copyWith(
                            color: selected ? Colors.white : c.textMuted,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          child: Text(label,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: _quick,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [color], darkened only as much as white bold text on it needs to read
/// well (contrast 4.5:1); already dark enough, it is left as it is.
Color readableFill(Color color) {
  double contrastWithWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);
  Color out = color;
  for (int i = 0; i < 20 && contrastWithWhite(out) < 4.5; i++) {
    out = Color.lerp(out, Colors.black, 0.06)!;
  }
  return out;
}

/// One page: the donut on the start side, the categories beside it. Keeps
/// its chosen category and "view all" while the other page is shown.
class _BreakdownPage extends ConsumerStatefulWidget {
  const _BreakdownPage({required this.type});
  final TransactionType type;

  @override
  ConsumerState<_BreakdownPage> createState() => _BreakdownPageState();
}

class _BreakdownPageState extends ConsumerState<_BreakdownPage>
    with AutomaticKeepAliveClientMixin<_BreakdownPage> {
  /// The category chosen in the list (index into all categories).
  int? _row;

  /// A slice chosen on the donut that is not one category ("Other").
  int? _slice;
  bool _all = false;

  /// Slices shown before "Other", as the dashboard always had.
  static const int _topN = 6;

  @override
  bool get wantKeepAlive => true;

  bool get _income => widget.type == TransactionType.income;

  /// Rows before "view all": five for income, six for expenses.
  int get _first => _income ? 5 : 6;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final AppLang lang = appLangOf(context);
    final List<CategoryTotal> totals = ref.watch(_income
        ? scopedIncomeCategoryTotalsProvider
        : scopedExpenseCategoryTotalsProvider);

    if (totals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.donut_large_outlined, size: 36, color: c.textFaint),
            const SizedBox(height: DsSpacing.sm),
            Text(_income ? l.incomeNoneInPeriod : l.expenseNoneInPeriod,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textMuted)),
          ],
        ),
      );
    }

    final String currency = totals.first.amount.currencyCode;
    final TextDirection dir = Directionality.of(context);
    final int total = totals.fold<int>(
        0, (int s, CategoryTotal t) => s + t.amount.minorUnits);
    final bool folded = totals.length > _topN;
    Color colorOf(int i) =>
        i < _topN ? DsChartPalette.at(i) : DsChartPalette.other;
    int sliceOf(int i) => i < _topN ? i : _topN;

    // The donut: top six and "Other", as before.
    final List<DonutSegment> segments = <DonutSegment>[
      for (int i = 0; i < totals.length && i < _topN; i++)
        DonutSegment(
          label: Catalog.label(totals[i].category, lang: lang),
          value: totals[i].amount.minorUnits.toDouble(),
          color: colorOf(i),
          valueLabel: _compact(totals[i].amount, dir),
        ),
      if (folded)
        DonutSegment(
          label: l.chartOther,
          value: totals
              .sublist(_topN)
              .fold<int>(0, (int s, CategoryTotal t) => s + t.amount.minorUnits)
              .toDouble(),
          color: DsChartPalette.other,
          valueLabel: _compact(
              Money(
                  totals.sublist(_topN).fold<int>(
                      0, (int s, CategoryTotal t) => s + t.amount.minorUnits),
                  currency),
              dir),
        ),
    ];

    // Keep the choice valid when the data changes under it.
    final int? row = (_row != null && _row! < totals.length) ? _row : null;
    final int? slice =
        (_slice != null && _slice! < segments.length) ? _slice : null;
    final int? chosen = row != null ? sliceOf(row) : slice;
    String? centerTop, centerBottom;
    if (row != null) {
      centerTop = _compact(totals[row].amount, dir);
      centerBottom = Catalog.label(totals[row].category, lang: lang);
    } else if (slice != null) {
      centerTop = segments[slice].valueLabel;
      centerBottom = segments[slice].label;
    }

    final int shown =
        _all ? totals.length : totals.length.clamp(0, _first).toInt();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 136,
          child: Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xs),
            child: Center(
              child: DonutChart(
                segments: segments,
                size: 130,
                thickness: 22,
                centerTop: _compact(Money(total, currency), dir),
                centerBottom: _income ? l.legendIncome : l.legendExpenses,
                selectedIndex: chosen,
                selectedCenterTop: centerTop,
                selectedCenterBottom: centerBottom,
                onSelectionChanged: (int? i) => setState(() {
                  // A slice that is one category chooses that category.
                  _row = (i != null && i < _topN) ? i : null;
                  _slice = (i != null && i >= _topN) ? i : null;
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: DsSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // A short list sits level with the donut; a long one fills
              // the page and scrolls inside it.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: shown,
                    itemBuilder: (BuildContext context, int i) => _CategoryRow(
                      label: Catalog.label(totals[i].category, lang: lang),
                      color: colorOf(i),
                      share:
                          total == 0 ? 0 : totals[i].amount.minorUnits / total,
                      selected: row == i,
                      onTap: () => setState(() {
                        _slice = null;
                        _row = row == i ? null : i;
                      }),
                    ),
                  ),
                ),
              ),
              if (totals.length > _first)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _all = !_all),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DsSpacing.sm, vertical: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                        _all ? l.viewLess : '${l.viewAll} (${totals.length})'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A category: its colour, its name and its share.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.color,
    required this.share,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double share;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final int pct = (share * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: DsRadius.brSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: DsRadius.brSm,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400)),
            ),
            const SizedBox(width: DsSpacing.xs),
            Text(pct == 0 && share > 0 ? '<1%' : '$pct%',
                style: t.labelSmall?.copyWith(
                    color: selected ? c.textPrimary : c.textMuted,
                    fontWeight: selected ? FontWeight.w700 : null)),
          ],
        ),
      ),
    );
  }
}

/// The compact amount (as everywhere: "€ 31K"). In a left-to-right layout
/// a currency written in Arabic letters is set apart, else the number is
/// pulled into it ("13.5 ر.سK"); right to left it reads well as it is.
String _compact(Money m, TextDirection dir) {
  final String s = MoneyFormatter.compact(m);
  if (dir == TextDirection.rtl) return s;
  final String symbol = m.currency.symbol;
  return s.replaceFirst(symbol, '\u2067$symbol\u2069');
}
