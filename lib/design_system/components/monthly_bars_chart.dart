import 'package:flutter/material.dart';

import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// Three grouped bars per month — income, expense and savings (net) — for a
/// 12-month [MonthPoint] series, matching the spreadsheet layout. A zero
/// baseline accommodates negative (loss) months. Colors are supplied by the
/// caller so it stays theme-aware.
class MonthlyBarsChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarsPainter(
          points: points,
          income: income,
          expense: expense,
          net: net,
          axis: axis,
          grid: grid,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.points,
    required this.income,
    required this.expense,
    required this.net,
    required this.axis,
    required this.grid,
  });

  final List<MonthPoint> points;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

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
    if (range <= 0) return;

    const double labelBand = 18;
    final double chartH = size.height - labelBand;
    final double zeroY = (maxPos / range) * chartH;
    final double groupW = size.width / points.length;

    final double barW = (groupW * 0.22).clamp(2.5, 13.0);
    const double innerGap = 2;
    final double totalBarsW = 3 * barW + 2 * innerGap;

    // Zero baseline.
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    final Paint incPaint = Paint()..color = income;
    final Paint expPaint = Paint()..color = expense;
    final Paint netPaint = Paint()..color = net;

    void bar(double left, int minor, Paint paint) {
      if (minor == 0) return;
      const Radius r = Radius.circular(2);
      final double len = (minor.abs() / range) * chartH;
      if (minor > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, zeroY - len, barW, len),
            topLeft: r,
            topRight: r,
          ),
          paint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, zeroY, barW, len),
            bottomLeft: r,
            bottomRight: r,
          ),
          paint,
        );
      }
    }

    for (int i = 0; i < points.length; i++) {
      final MonthPoint p = points[i];
      final double groupStart = groupW * i + (groupW - totalBarsW) / 2;
      bar(groupStart, p.income.minorUnits, incPaint);
      bar(groupStart + barW + innerGap, p.expense.minorUnits, expPaint);
      bar(groupStart + 2 * (barW + innerGap), p.net.minorUnits, netPaint);

      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: '${i + 1}', style: TextStyle(color: axis, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(groupW * i + groupW / 2 - tp.width / 2, chartH + 5),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.points != points ||
      old.income != income ||
      old.expense != expense ||
      old.net != net;
}
