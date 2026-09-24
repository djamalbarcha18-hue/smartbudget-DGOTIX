import 'package:flutter/material.dart';

/// The calm scene behind the app's glass: the page color as a gentle gradient
/// with a couple of very soft light pools in the brand blue. It is what gives the translucent surfaces something
/// to refract — without it, glass on a flat color just looks grey.
///
/// Static and cheap: painted once inside a [RepaintBoundary] and only repainted
/// when the theme changes.
class DsBackdrop extends StatelessWidget {
  const DsBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: dark ? _BackdropPainter.dark : _BackdropPainter.light,
        size: Size.infinite,
      ),
    );
  }
}

class _Glow {
  const _Glow(this.center, this.radius, this.color);

  /// Center as a fraction of the canvas (0..1 on each axis).
  final Offset center;

  /// Radius as a fraction of the canvas' longest side.
  final double radius;
  final Color color;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.top,
    required this.bottom,
    required this.glows,
  });

  final Color top;
  final Color bottom;
  final List<_Glow> glows;

  // The original page colors, with a very soft DGOTIX-blue light so the glass
  // has depth — calm, a single hue, nothing competing with the data.
  static const _BackdropPainter dark = _BackdropPainter(
    top: Color(0xFF0E1628),
    bottom: Color(0xFF0B1120),
    glows: <_Glow>[
      _Glow(Offset(0.92, 0.02), 0.55, Color(0x261680F7)),
      _Glow(Offset(0.10, 0.90), 0.50, Color(0x141680F7)),
    ],
  );

  static const _BackdropPainter light = _BackdropPainter(
    top: Color(0xFFF7FAFD),
    bottom: Color(0xFFF0F4F9),
    glows: <_Glow>[
      _Glow(Offset(0.92, 0.02), 0.55, Color(0x171680F7)),
      _Glow(Offset(0.10, 0.90), 0.50, Color(0x0F1680F7)),
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, bottom],
        ).createShader(rect),
    );
    final double longest = size.longestSide;
    for (final _Glow g in glows) {
      final Offset c = Offset(g.center.dx * size.width, g.center.dy * size.height);
      final double r = g.radius * longest;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[g.color, g.color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.top != top || old.bottom != bottom || old.glows != glows;
}
