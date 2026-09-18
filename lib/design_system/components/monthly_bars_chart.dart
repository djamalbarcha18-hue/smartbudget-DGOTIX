import 'package:flutter/material.dart';

import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// Grouped income/expense bars per month with a net (savings) line overlay,
/// for a 12-month [MonthPoint] series. Colors are supplied by the caller so it
/// stays theme-aware.
class MonthlyBarsChart extends StatelessWidget {
  const MonthlyBarsChart({
    super.key,
    required this.points,
    required this.income,
    required this.expense,
    required this.net,
    required this.axis,
    required this.grid,
    this.height = 200,
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
    int maxMinor = 0;
    for (final MonthPoint p in points) {
      maxMinor = <int>[
        maxMinor,
        p.income.minorUnits,
        p.expense.minorUnits,
        p.net.minorUnits,
      ].reduce((int a, int b) => a > b ? a : b);
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarsPainter(
          points: points,
          maxMinor: maxMinor,
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
    required this.maxMinor,
    required this.income,
    required this.expense,
    required this.net,
    required this.axis,
    required this.grid,
  });

  final List<MonthPoint> points;
  final int maxMinor;
  final Color income;
  final Color expense;
  final Color net;
  final Color axis;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxMinor <= 0) return;
    const double labelBand = 18;
    final double chartH = size.height - labelBand;
    final double baseY = chartH;
    final double groupW = size.width / points.length;
    final double barW = (groupW * 0.26).clamp(3.0, 16.0);
    const double gap = 2;

    // Baseline.
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    final Paint incPaint = Paint()..color = income;
    final Paint expPaint = Paint()..color = expense;
    const Radius r = Radius.circular(2);

    double h(int minor) => (minor / maxMinor) * (chartH - 4);

    // Bars.
    for (int i = 0; i < points.length; i++) {
      final MonthPoint p = points[i];
      final double centre = groupW * i + groupW / 2;
      final double incH = h(p.income.minorUnits);
      final double expH = h(p.expense.minorUnits);
      final double incLeft = centre - barW - gap / 2;
      final double expLeft = centre + gap / 2;

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

      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: '${i + 1}', style: TextStyle(color: axis, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centre - tp.width / 2, baseY + 5));
    }

    // Net (savings) line — negative months clamp to the baseline.
    final Path line = Path();
    final List<Offset> dots = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final double centre = groupW * i + groupW / 2;
      final int netMinor = points[i].net.minorUnits;
      final double y = baseY - h(netMinor < 0 ? 0 : netMinor);
      final Offset o = Offset(centre, y);
      dots.add(o);
      if (i == 0) {
        line.moveTo(o.dx, o.dy);
      } else {
        line.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = net
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final Offset o in dots) {
      canvas.drawCircle(o, 2.4, Paint()..color = net);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.points != points || old.maxMinor != maxMinor;
}
