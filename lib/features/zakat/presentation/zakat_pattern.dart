import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// The zakat screen's background: a faint geometric pattern of eight-pointed
/// stars (khatam) linked in a grid, in the brand colour at a very low
/// opacity, over a soft wash. Calm in light and dark, never behind text at
/// a strength that hurts reading. Used on this screen only.
class ZakatPatternBackground extends StatelessWidget {
  const ZakatPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      c.brand.withValues(alpha: dark ? 0.08 : 0.05),
                      c.brand.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: KhatamPainter(
                      color: c.brand.withValues(alpha: dark ? 0.09 : 0.07)),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Eight-pointed stars, one per tile, each made of two overlapping squares,
/// with lines joining neighbouring stars point to point.
class KhatamPainter extends CustomPainter {
  KhatamPainter({required this.color, this.tile = 64});

  final Color color;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final double r = tile * 0.30; // star radius (to a point)
    final Path star = _star(r);
    for (double y = 0; y < size.height + tile; y += tile) {
      for (double x = 0; x < size.width + tile; x += tile) {
        final Offset o = Offset(x, y);
        canvas.drawPath(star.shift(o), p);
        // Point to point links with the next star right and below.
        canvas.drawLine(o + Offset(r, 0), o + Offset(tile - r, 0), p);
        canvas.drawLine(o + Offset(0, r), o + Offset(0, tile - r), p);
      }
    }
  }

  static Path _star(double r) {
    final Path path = Path();
    for (int k = 0; k < 2; k++) {
      final double a0 = k * math.pi / 4;
      for (int i = 0; i < 4; i++) {
        final double a = a0 + i * math.pi / 2;
        final Offset pt = Offset(r * math.cos(a), r * math.sin(a));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
    }
    return path;
  }

  @override
  bool shouldRepaint(KhatamPainter old) =>
      old.color != color || old.tile != tile;
}
