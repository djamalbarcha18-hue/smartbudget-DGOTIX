import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
}

/// A donut (ring) chart. Pure presentation — the caller supplies segments
/// (already aggregated/sorted). Renders nothing meaningful when the total is 0.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 132,
    this.thickness = 24,
    this.centerTop,
    this.centerBottom,
    this.trackColor,
  });

  final List<DonutSegment> segments;
  final double size;
  final double thickness;

  /// Optional two-line center label (e.g. total + caption).
  final String? centerTop;
  final String? centerBottom;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final double total =
        segments.fold<double>(0, (double s, DonutSegment e) => s + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: total > 0 ? segments : const <DonutSegment>[],
          thickness: thickness,
          track: trackColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        child: (centerTop != null || centerBottom != null)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (centerTop != null)
                      Text(centerTop!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    if (centerBottom != null)
                      Text(centerBottom!,
                          style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.track,
  });

  final List<DonutSegment> segments;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = (math.min(size.width, size.height) - thickness) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: r);

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(center, r, trackPaint);

    final double total =
        segments.fold<double>(0, (double s, DonutSegment e) => s + e.value);
    if (total <= 0) return;

    const double gap = 0.03; // small radian gap between slices
    double start = -math.pi / 2;
    for (final DonutSegment seg in segments) {
      final double sweep = (seg.value / total) * (2 * math.pi);
      if (sweep <= 0) continue;
      final Paint p = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt;
      final double drawSweep = sweep > gap ? sweep - gap : sweep;
      canvas.drawArc(rect, start, drawSweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.track != track;
}
