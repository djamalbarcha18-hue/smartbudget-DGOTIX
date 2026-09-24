import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

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
    required this.left,
    required this.gridValues,
    required this.valueToY,
  });
  final List<_BarHit> bars;
  final double zeroY;
  final double chartH;
  final double groupW;
  final int count;

  /// Start of the plot area (after the value-axis labels).
  final double left;

  /// Gridline values (minor units), from the lowest to the highest.
  final List<int> gridValues;
  final double Function(int minor) valueToY;
}

/// A "nice" step (1, 2, 2.5 or 5 × 10^k) so gridlines land on round numbers.
int _niceStep(int roughMinor) {
  if (roughMinor <= 0) return 1;
  int mag = 1;
  while (mag * 10 <= roughMinor) {
    mag *= 10;
  }
  for (final double m in <double>[1, 2, 2.5, 5, 10]) {
    final int step = (mag * m).round();
    if (step >= roughMinor) return step;
  }
  return mag * 10;
}

_BarsLayout _layout(Size size, List<MonthPoint> points, {double axisW = 0}) {
  const double labelBand = 22;
  final double chartH = size.height - labelBand;
  final int count = points.length;
  final double plotW = size.width - axisW;
  final double groupW = count == 0 ? 0 : plotW / count;

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
  if (maxPos + negAbs <= 0) {
    return _BarsLayout(
        bars: const <_BarHit>[],
        zeroY: chartH,
        chartH: chartH,
        groupW: groupW,
        count: count,
        left: axisW,
        gridValues: const <int>[],
        valueToY: (_) => chartH);
  }

  // Round the scale out to whole gridline steps (4 bands above zero).
  final int step = _niceStep(((maxPos > 0 ? maxPos : negAbs) / 4).ceil());
  final int top = maxPos <= 0 ? 0 : step * (maxPos / step).ceil();
  final int bottom = negAbs <= 0 ? 0 : step * (negAbs / step).ceil();
  final int range = top + bottom;
  final double topPad = 6;
  final double usableH = chartH - topPad;
  double y(int minor) => topPad + ((top - minor) / range) * usableH;
  final double zeroY = y(0);

  final double barW = (groupW * 0.2).clamp(3.0, 14.0);
  const double innerGap = 3;
  final double totalBarsW = 3 * barW + 2 * innerGap;

  final List<_BarHit> bars = <_BarHit>[];
  for (int i = 0; i < count; i++) {
    final MonthPoint p = points[i];
    final double groupStart = axisW + groupW * i + (groupW - totalBarsW) / 2;
    final List<int> vals = <int>[
      p.income.minorUnits,
      p.expense.minorUnits,
      p.net.minorUnits,
    ];
    for (int s = 0; s < 3; s++) {
      final int minor = vals[s];
      final double left = groupStart + s * (barW + innerGap);
      final double end = y(minor);
      final Rect rect = minor >= 0
          ? Rect.fromLTRB(left, end, left + barW, zeroY)
          : Rect.fromLTRB(left, zeroY, left + barW, end);
      bars.add(_BarHit(rect, minor, i, s));
    }
  }
  return _BarsLayout(
      bars: bars,
      zeroY: zeroY,
      chartH: chartH,
      groupW: groupW,
      count: count,
      left: axisW,
      gridValues: <int>[
        for (int v = -bottom; v <= top; v += step) v,
      ],
      valueToY: y);
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
    this.height = 240,
    this.monthLabels,
  });

  final List<MonthPoint> points;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;
  final double height;

  /// Axis labels for each point (e.g. month names); defaults to 1..12.
  final List<String>? monthLabels;

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

  /// Room for the value-axis labels.
  static const double _axisWidth = 44;

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
          final _BarsLayout layout =
              _layout(size, widget.points, axisW: _axisWidth);
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
                      currency: _currency,
                      monthLabels: widget.monthLabels,
                      // The app font, so axis text renders like all other
                      // text (a bare TextStyle falls back to a font the web
                      // build may not have loaded).
                      labelStyle: Theme.of(context).textTheme.labelSmall ??
                          const TextStyle(),
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
    required this.currency,
    required this.labelStyle,
    this.monthLabels,
    this.selected,
  });

  final _BarsLayout layout;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;
  final String currency;
  final TextStyle labelStyle;
  final List<String>? monthLabels;
  final ({int month, int series})? selected;

  Color _color(int s) => s == 0 ? income : (s == 1 ? expense : net);

  static final NumberFormat _compact = NumberFormat.compact(locale: 'en');

  void _text(Canvas canvas, String text, Offset at, TextAlign align,
      {double size = 10.5}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
          text: text,
          style: labelStyle.copyWith(
              color: axis, fontSize: size, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    final double dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.count == 0) return;

    // Gridlines with round value labels (Latin digits, compact).
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final int v in layout.gridValues) {
      final double y = layout.valueToY(v);
      canvas.drawLine(Offset(layout.left, y), Offset(size.width, y),
          v == 0 ? (Paint()..color = axis.withValues(alpha: 0.45)) : gridPaint);
      // v == 0 is spelled out: on the web `-0` survives and prints as "-0".
      _text(canvas, v == 0 ? '0' : _compact.format(Money(v, currency).asDouble),
          Offset(layout.left - 8, y), TextAlign.right);
    }

    // Soft column highlight behind the active month.
    if (selected != null) {
      final double x = layout.left + layout.groupW * selected!.month;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, 0, layout.groupW - 4, layout.chartH),
            const Radius.circular(8)),
        Paint()..color = axis.withValues(alpha: 0.08),
      );
    }

    const Radius r = Radius.circular(4);
    for (final _BarHit b in layout.bars) {
      if (b.minor == 0) continue;
      final bool dim = selected != null &&
          (selected!.month != b.month || selected!.series != b.series);
      final Color col = _color(b.series).withValues(alpha: dim ? 0.28 : 1.0);
      // Vertical gradient: full color at the value end, fading to the base.
      final Paint paint = Paint()
        ..shader = LinearGradient(
          begin: b.minor > 0 ? Alignment.topCenter : Alignment.bottomCenter,
          end: b.minor > 0 ? Alignment.bottomCenter : Alignment.topCenter,
          colors: <Color>[col, col.withValues(alpha: col.a * 0.35)],
        ).createShader(b.rect);
      final RRect rr = b.minor > 0
          ? RRect.fromRectAndCorners(b.rect, topLeft: r, topRight: r)
          : RRect.fromRectAndCorners(b.rect, bottomLeft: r, bottomRight: r);
      canvas.drawRRect(rr, paint);
    }

    // Month labels centered under each group; month numbers when the names
    // would collide (narrow phones).
    List<String>? labels = monthLabels;
    if (labels != null) {
      for (final String name in labels) {
        final TextPainter probe = TextPainter(
          text: TextSpan(text: name, style: labelStyle.copyWith(fontSize: 10.5)),
          textDirection: TextDirection.ltr,
        )..layout();
        if (probe.width > layout.groupW - 4) {
          labels = null;
          break;
        }
      }
    }
    for (int i = 0; i < layout.count; i++) {
      final String label =
          (labels != null && i < labels.length) ? labels[i] : '${i + 1}';
      _text(
        canvas,
        label,
        Offset(layout.left + layout.groupW * i + layout.groupW / 2,
            layout.chartH + 12),
        TextAlign.center,
        size: 10.5,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.layout != layout ||
      old.income != income ||
      old.expense != expense ||
      old.net != net ||
      old.axis != axis ||
      old.grid != grid ||
      old.monthLabels != monthLabels ||
      old.labelStyle != labelStyle ||
      old.selected != selected;
}
