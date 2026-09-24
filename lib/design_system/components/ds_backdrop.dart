import 'package:flutter/material.dart';

/// The ambient scene behind the app's glass: a deep gradient with a few large,
/// very soft light pools. It is what gives the translucent surfaces something
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

  static const _BackdropPainter dark = _BackdropPainter(
    top: Color(0xFF071A2A),
    bottom: Color(0xFF040B14),
    glows: <_Glow>[
      _Glow(Offset(0.92, 0.02), 0.55, Color(0x4714B8A6)), // teal, top corner
      _Glow(Offset(0.18, 0.28), 0.45, Color(0x291D4ED8)), // deep blue
      _Glow(Offset(0.06, 0.98), 0.50, Color(0x3810B981)), // emerald, low corner
      _Glow(Offset(0.70, 0.85), 0.40, Color(0x2406B6D4)), // cyan haze
    ],
  );

  static const _BackdropPainter light = _BackdropPainter(
    top: Color(0xFFF1F7FA),
    bottom: Color(0xFFE5EEF3),
    glows: <_Glow>[
      _Glow(Offset(0.92, 0.02), 0.55, Color(0x2614B8A6)),
      _Glow(Offset(0.18, 0.30), 0.45, Color(0x1A38BDF8)),
      _Glow(Offset(0.06, 0.98), 0.50, Color(0x1A10B981)),
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
