import 'package:flutter/material.dart';

/// A savings-jar (money jar) glyph — a coin bank WITHOUT the piggy shape.
///
/// Outline style, matching the app's other `*_outlined` icons. It reads the
/// ambient [IconTheme] for colour/size (like a real [Icon]), so it can be
/// dropped anywhere an icon is expected — including inside the KPI icon chip.
class SavingsJarGlyph extends StatelessWidget {
  const SavingsJarGlyph({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final IconThemeData it = IconTheme.of(context);
    final double sz = size ?? it.size ?? 18;
    final Color col = color ?? it.color ?? const Color(0xFF000000);
    return SizedBox(
      width: sz,
      height: sz,
      child: CustomPaint(painter: _JarPainter(col)),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 24×24 coordinate box, then scale to the requested size.
    final double s = size.width / 24.0;
    canvas.save();
    canvas.scale(s);

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Jar body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(4.5, 7.6, 19.5, 21.0),
        const Radius.circular(4),
      ),
      stroke,
    );

    // Lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(6.5, 4.8, 17.5, 7.8),
        const Radius.circular(1.8),
      ),
      stroke,
    );

    // Coin slot on the lid.
    canvas.drawLine(const Offset(10, 6.3), const Offset(14, 6.3), stroke);

    // A coin dropping in.
    canvas.drawCircle(const Offset(12, 2.4), 1.8, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_JarPainter oldDelegate) => oldDelegate.color != color;
}
