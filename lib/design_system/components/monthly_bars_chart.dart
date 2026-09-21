import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// One drawable bar: its rectangle, signed value, month index and series
/// (0 = income, 1 = expense, 2 = net).
class _BarHit {
  const _BarHit(this.rect, this.minor, this.month, this.series);
  final Rect rect;
  final int minor;
  final int month;
  final int series;
}

/// Full chart geometry, computed once and shared by the painter (to draw) and
/// the widget (to hit-test taps/hover) so both agree exactly.
class _BarsLayout {
  const _BarsLayout({
    required this.bars,
    required this.zeroY,
    required this.chartH,
    required this.groupW,
    required this.count,
  });
  final List<_BarHit> bars;
  final double zeroY;
  final double chartH;
  final double groupW;
  final int count;
}

_BarsLayout _layout(Size size, List<MonthPoint> points) {
  const double labelBand = 18;
  final double chartH = size.height - labelBand;
  final int count = points.length;
  final double groupW = count == 0 ? 0 : size.width / count;

  int maxPos = 0;
  int negAbs = 0;
  for (final MonthPoint p in points) {
    for (final int v in <int>[
      p.income.minorUnits,
      p.expense.minorUnits,
      p.net.minorUnits,
    ]) {
      if (v > maxPos) maxPos = v;
      if (v < 0 && -v > negAbs) negAbs = -v;
    }
  }
  final int range = maxPos + negAbs;
  if (range <= 0) {
    return _BarsLayout(
        bars: const <_BarHit>[],
        zeroY: chartH,
        chartH: chartH,
        groupW: groupW,
        count: count);
  }

  final double zeroY = (maxPos / range) * chartH;
  final double barW = (groupW * 0.22).clamp(2.5, 13.0);
  const double innerGap = 2;
  final double totalBarsW = 3 * barW + 2 * innerGap;

  final List<_BarHit> bars = <_BarHit>[];
  for (int i = 0; i < count; i++) {
    final MonthPoint p = points[i];
    final double groupStart = groupW * i + (groupW - totalBarsW) / 2;
    final List<int> vals = <int>[
      p.income.minorUnits,
      p.expense.minorUnits,
      p.net.minorUnits,
    ];
    for (int s = 0; s < 3; s++) {
      final int minor = vals[s];
      final double left = groupStart + s * (barW + innerGap);
      final double len = (minor.abs() / range) * chartH;
      final Rect rect = minor >= 0
          ? Rect.fromLTWH(left, zeroY - len, barW, len)
          : Rect.fromLTWH(left, zeroY, barW, len);
      bars.add(_BarHit(rect, minor, i, s));
    }
  }
  return _BarsLayout(
      bars: bars,
      zeroY: zeroY,
      chartH: chartH,
      groupW: groupW,
      count: count);
}

/// Three grouped bars per month — income, expense and savings (net) — for a
/// 12-month [MonthPoint] series. Tapping (or hovering) a bar reveals its value;
/// tapping the same bar again hides it. A zero baseline accommodates negative
/// (loss) months. Colors are supplied by the caller so it stays theme-aware.
class MonthlyBarsChart extends StatefulWidget {
  const MonthlyBarsChart({
    super.key,
    required this.points,
    required this.income,
    required this.expense,
    required this.net,
    required this.axis,
    required this.grid,
    this.height = 220,
  });

  final List<MonthPoint> points;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;
  final double height;

  @override
  State<MonthlyBarsChart> createState() => _MonthlyBarsChartState();
}

class _MonthlyBarsChartState extends State<MonthlyBarsChart> {
  ({int month, int series})? _tapped;
  ({int month, int series})? _hover;

  ({int month, int series})? get _active => _hover ?? _tapped;

  Color _seriesColor(int s) =>
      s == 0 ? widget.income : (s == 1 ? widget.expense : widget.net);

  String get _currency =>
      widget.points.isEmpty ? 'USD' : widget.points.first.income.currencyCode;

  _BarHit? _hitAt(Offset local, List<_BarHit> bars) {
    for (final _BarHit b in bars) {
      if (b.rect.inflate(2).contains(local)) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, widget.height);
          final _BarsLayout layout = _layout(size, widget.points);
          final ({int month, int series})? active = _active;
          _BarHit? sel;
          if (active != null) {
            for (final _BarHit b in layout.bars) {
              if (b.month == active.month && b.series == active.series) {
                sel = b;
                break;
              }
            }
          }

          return MouseRegion(
            onHover: (e) {
              final _BarHit? h = _hitAt(e.localPosition, layout.bars);
              final ({int month, int series})? next =
                  h == null ? null : (month: h.month, series: h.series);
              if (next != _hover) setState(() => _hover = next);
            },
            onExit: (_) {
              if (_hover != null) setState(() => _hover = null);
            },
            child: GestureDetector(
              onTapDown: (d) {
                final _BarHit? h = _hitAt(d.localPosition, layout.bars);
                if (h == null) return;
                final ({int month, int series}) k =
                    (month: h.month, series: h.series);
                setState(() => _tapped = _tapped == k ? null : k);
              },
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: size,
                    painter: _BarsPainter(
                      layout: layout,
                      income: widget.income,
                      expense: widget.expense,
                      net: widget.net,
                      axis: widget.axis,
                      grid: widget.grid,
                      selected: active,
                    ),
                  ),
                  if (sel != null)
                    _BarTooltip(
                      hit: sel,
                      currency: _currency,
                      color: _seriesColor(sel.series),
                      chartWidth: size.width,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A floating value label positioned above (or below, for losses) the selected
/// bar.
class _BarTooltip extends StatelessWidget {
  const _BarTooltip({
    required this.hit,
    required this.currency,
    required this.color,
    required this.chartWidth,
  });
  final _BarHit hit;
  final String currency;
  final Color color;
  final double chartWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String text = MoneyFormatter.compact(Money(hit.minor, currency));
    const double w = 88;
    final double left =
        (hit.rect.center.dx - w / 2).clamp(0.0, (chartWidth - w).clamp(0.0, chartWidth));
    final bool below = hit.minor < 0;
    final double top = below
        ? hit.rect.bottom + 4
        : (hit.rect.top - 26).clamp(0.0, hit.rect.top);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: w,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.layout,
    required this.income,
    required this.expense,
    required this.net,
    required this.axis,
    required this.grid,
    this.selected,
  });

  final _BarsLayout layout;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;
  final ({int month, int series})? selected;

  Color _color(int s) => s == 0 ? income : (s == 1 ? expense : net);

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.count == 0) return;

    // Zero baseline.
    canvas.drawLine(
      Offset(0, layout.zeroY),
      Offset(size.width, layout.zeroY),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    const Radius r = Radius.circular(2);
    for (final _BarHit b in layout.bars) {
      if (b.minor == 0) continue;
      final bool dim = selected != null &&
          (selected!.month != b.month || selected!.series != b.series);
      final Paint paint = Paint()
        ..color = _color(b.series).withValues(alpha: dim ? 0.28 : 1.0);
      final RRect rr = b.minor > 0
          ? RRect.fromRectAndCorners(b.rect, topLeft: r, topRight: r)
          : RRect.fromRectAndCorners(b.rect, bottomLeft: r, bottomRight: r);
      canvas.drawRRect(rr, paint);
    }

    // Month labels (1..12) centered under each group.
    for (int i = 0; i < layout.count; i++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: '${i + 1}', style: TextStyle(color: axis, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(layout.groupW * i + layout.groupW / 2 - tp.width / 2,
            layout.chartH + 5),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.layout != layout ||
      old.income != income ||
      old.expense != expense ||
      old.net != net ||
      old.selected != selected;
}
