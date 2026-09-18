import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// A tiny line chart for a short price series. Colour follows the trend
/// (last vs first): up = income green, down = expense red.
class Sparkline extends StatelessWidget {
  const Sparkline(this.points, {super.key, this.width = 120, this.height = 34});

  final List<double> points;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    if (points.length < 2) return SizedBox(width: width, height: height);
    final Color color =
        points.last >= points.first ? c.income : c.expense;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparkPainter(points, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    double min = points.first;
    double max = points.first;
    for (final double p in points) {
      if (p < min) min = p;
      if (p > max) max = p;
    }
    final double span = (max - min).abs() < 1e-9 ? 1 : (max - min);
    final double dx = size.width / (points.length - 1);

    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final double x = dx * i;
      final double y = size.height - ((points[i] - min) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Soft fill under the line.
    final Path fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.10),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.color != color;
}
