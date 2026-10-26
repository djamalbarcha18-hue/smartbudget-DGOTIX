import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';

/// The colours of a metal: its polished faces, its shadowed edges and the
/// ink its engravings and text are cut in.
class MetalPalette {
  const MetalPalette({
    required this.shine,
    required this.light,
    required this.mid,
    required this.dark,
    required this.edge,
    required this.ink,
  });

  final Color shine;
  final Color light;
  final Color mid;
  final Color dark;
  final Color edge;
  final Color ink;

  static MetalPalette of(Metal m) => switch (m) {
        Metal.gold => const MetalPalette(
            shine: Color(0xFFFFF4C9),
            light: Color(0xFFF5D67A),
            mid: Color(0xFFDCAE3E),
            dark: Color(0xFFA97B16),
            edge: Color(0xFF8A6410),
            ink: Color(0xFF4A3200),
          ),
        Metal.silver => const MetalPalette(
            shine: Color(0xFFFFFFFF),
            light: Color(0xFFEDEFF2),
            mid: Color(0xFFC9CED5),
            dark: Color(0xFF8F96A0),
            edge: Color(0xFF7A828D),
            ink: Color(0xFF2B323B),
          ),
        Metal.platinum => const MetalPalette(
            shine: Color(0xFFF4F8FB),
            light: Color(0xFFD6DFE6),
            mid: Color(0xFFA9B7C3),
            dark: Color(0xFF6F808E),
            edge: Color(0xFF5E6E7C),
            ink: Color(0xFF1C2A36),
          ),
        Metal.palladium => const MetalPalette(
            shine: Color(0xFFFAF7F2),
            light: Color(0xFFE3DED6),
            mid: Color(0xFFBDB5A9),
            dark: Color(0xFF857C70),
            edge: Color(0xFF6E665B),
            ink: Color(0xFF2C2620),
          ),
      };

  /// A polished face catching the light from the top corner.
  LinearGradient get polish => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[mid, light, shine, light, mid, dark],
        stops: const <double>[0, 0.22, 0.42, 0.58, 0.82, 1],
      );
}

/// What is stamped on a bar: the metal's symbol and its fineness.
abstract final class MetalStamp {
  static String symbol(Metal m) => switch (m) {
        Metal.gold => 'Au',
        Metal.silver => 'Ag',
        Metal.platinum => 'Pt',
        Metal.palladium => 'Pd',
      };

  static String fineness(Metal m) => switch (m) {
        Metal.gold => '999.9',
        Metal.silver => '999.0',
        Metal.platinum => '999.5',
        Metal.palladium => '999.5',
      };
}

/// A cast bar of [metal], seen from the front and a little above, with its
/// symbol and fineness struck on the top.
class MetalBar extends StatelessWidget {
  const MetalBar({super.key, required this.metal, this.width = 64});

  final Metal metal;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.66,
      child: CustomPaint(painter: _BarPainter(metal)),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.metal) : p = MetalPalette.of(metal);

  final Metal metal;
  final MetalPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // The shadow it casts on the table.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.93), width: w * 0.98, height: h * 0.12),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    final Offset backL = Offset(w * 0.2, h * 0.06);
    final Offset backR = Offset(w * 0.8, h * 0.06);
    final Offset frontL = Offset(w * 0.11, h * 0.56);
    final Offset frontR = Offset(w * 0.89, h * 0.56);
    final Offset baseL = Offset(w * 0.02, h * 0.9);
    final Offset baseR = Offset(w * 0.98, h * 0.9);

    final Path top = Path()
      ..moveTo(backL.dx, backL.dy)
      ..lineTo(backR.dx, backR.dy)
      ..lineTo(frontR.dx, frontR.dy)
      ..lineTo(frontL.dx, frontL.dy)
      ..close();
    final Path front = Path()
      ..moveTo(frontL.dx, frontL.dy)
      ..lineTo(frontR.dx, frontR.dy)
      ..lineTo(baseR.dx, baseR.dy)
      ..lineTo(baseL.dx, baseL.dy)
      ..close();

    final Rect box = Offset.zero & size;
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[p.mid, p.dark],
        ).createShader(box),
    );
    canvas.drawPath(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[p.light, p.shine, p.light, p.mid],
          stops: const <double>[0, 0.35, 0.6, 1],
        ).createShader(box),
    );

    // A streak of light across the top.
    canvas.save();
    canvas.clipPath(top);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, 0)
        ..lineTo(w * 0.56, 0)
        ..lineTo(w * 0.4, h * 0.6)
        ..lineTo(w * 0.26, h * 0.6)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.restore();

    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, w / 90)
      ..color = p.edge.withValues(alpha: 0.8);
    canvas.drawPath(top, outline);
    canvas.drawPath(front, outline);

    // The struck panel and what is stamped in it.
    final Rect panel = Rect.fromLTRB(w * 0.27, h * 0.14, w * 0.73, h * 0.49);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, Radius.circular(w * 0.03)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, w / 120)
        ..color = p.ink.withValues(alpha: 0.35),
    );
    final bool small = w < 54;
    _engrave(
        canvas,
        MetalStamp.symbol(metal),
        Offset(
            w / 2, small ? panel.center.dy : panel.top + panel.height * 0.38),
        panel.height * (small ? 0.62 : 0.5));
    if (!small) {
      _engrave(canvas, MetalStamp.fineness(metal),
          Offset(w / 2, panel.top + panel.height * 0.8), panel.height * 0.24);
    }
  }

  /// Text cut into the metal: a dark cut with a bright lower lip.
  void _engrave(Canvas canvas, String text, Offset center, double fontSize) {
    for (final (Offset shift, Color color) in <(Offset, Color)>[
      (const Offset(0, 0.7), Colors.white.withValues(alpha: 0.6)),
      (Offset.zero, p.ink.withValues(alpha: 0.7)),
    ]) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: fontSize * 0.04,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center + shift - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.metal != metal;
}

/// A card polished in the colours of [metal] and engraved with its own
/// pattern: a rosette for gold, waves for silver, a fine lattice for
/// platinum, a honeycomb for palladium. Its [child] is written in the metal's ink.
class MetalPlate extends StatelessWidget {
  const MetalPlate({
    super.key,
    required this.metal,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Metal metal;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final MetalPalette p = MetalPalette.of(metal);
    return Container(
      decoration: BoxDecoration(
        borderRadius: DsRadius.brLg,
        gradient: p.polish,
        border: Border.all(color: p.edge.withValues(alpha: 0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.dark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: DsRadius.brLg,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: CustomPaint(
              painter: _EngravingPainter(metal, Directionality.of(context)),
              child: Padding(
                padding: padding,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: p.ink),
                  child: IconTheme.merge(
                    data: IconThemeData(color: p.ink),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EngravingPainter extends CustomPainter {
  _EngravingPainter(this.metal, this.direction) : p = MetalPalette.of(metal);

  final Metal metal;
  final TextDirection direction;
  final MetalPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint cut = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = p.ink.withValues(alpha: 0.1);
    final Paint lip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.28);
    // The pattern sits at the far end, away from where the text starts.
    final bool rtl = direction == TextDirection.rtl;
    switch (metal) {
      case Metal.gold:
        // Half a rosette rising from the far edge, its petals meeting there.
        final Offset c = Offset(rtl ? 0 : size.width, size.height / 2);
        final double r = size.height * 0.9;
        for (int i = 0; i < 36; i++) {
          final double a = i * math.pi * 2 / 36;
          final Offset o = c + Offset(math.cos(a), math.sin(a)) * r * 0.5;
          canvas.drawCircle(o + const Offset(0, 0.8), r * 0.5, lip);
          canvas.drawCircle(o, r * 0.5, cut);
        }
        canvas.drawCircle(c, r * 1.04, cut);
        canvas.drawCircle(c, r * 1.1, cut);
      case Metal.silver:
        for (double y = -6; y < size.height + 12; y += 7) {
          final Path wave = Path()..moveTo(0, y);
          for (double x = 0; x <= size.width; x += 4) {
            wave.lineTo(x, y + math.sin(x / 14 + y / 9) * 3.2);
          }
          canvas.drawPath(wave.shift(const Offset(0, 0.8)), lip);
          canvas.drawPath(wave, cut);
        }
      case Metal.platinum:
        const double step = 9;
        final double span = size.width + size.height;
        for (double d = -size.height; d < span; d += step) {
          for (final (Paint paint, double dy) in <(Paint, double)>[
            (lip, 0.8),
            (cut, 0),
          ]) {
            canvas.drawLine(Offset(d, dy),
                Offset(d + size.height, size.height + dy), paint);
            canvas.drawLine(Offset(d + size.height, dy),
                Offset(d, size.height + dy), paint);
          }
        }
      case Metal.palladium:
        // A honeycomb of small hexagons.
        const double r = 7;
        final double hx = r * math.sqrt(3);
        int row = 0;
        for (double y = -r; y < size.height + r; y += r * 1.5, row++) {
          for (double x = (row.isOdd ? hx / 2 : 0) - hx;
              x < size.width + hx;
              x += hx) {
            final Path hex = Path();
            for (int k = 0; k < 6; k++) {
              final double a = math.pi / 6 + k * math.pi / 3;
              final Offset o = Offset(x + r * math.cos(a), y + r * math.sin(a));
              k == 0 ? hex.moveTo(o.dx, o.dy) : hex.lineTo(o.dx, o.dy);
            }
            hex.close();
            canvas.drawPath(hex.shift(const Offset(0, 0.8)), lip);
            canvas.drawPath(hex, cut);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_EngravingPainter old) =>
      old.metal != metal || old.direction != direction;
}
