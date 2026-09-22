import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    this.valueLabel,
  });
  final String label;
  final double value;
  final Color color;

  /// Optional pre-formatted value shown when this slice is selected/hovered.
  final String? valueLabel;
}

/// A donut (ring) chart. Pure presentation — the caller supplies segments
/// (already aggregated/sorted). Tapping or hovering a slice reveals its value
/// in the center; tapping the same slice again hides it. Renders nothing
/// meaningful when the total is 0.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 132,
    this.thickness = 24,
    this.centerTop,
    this.centerBottom,
    this.trackColor,
    this.selectedIndex,
    this.onSelectionChanged,
  });

  final List<DonutSegment> segments;
  final double size;
  final double thickness;

  /// Optional two-line center label (e.g. total + caption) shown when nothing
  /// is selected.
  final String? centerTop;
  final String? centerBottom;
  final Color? trackColor;

  /// Controlled selection. When [onSelectionChanged] is provided the chart is
  /// "controlled": the sticky selection is driven by [selectedIndex] and taps
  /// report through the callback (so the selection can be shared with a sibling
  /// chart). When null, the chart manages its own tap selection internally.
  final int? selectedIndex;
  final ValueChanged<int?>? onSelectionChanged;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _tapped; // sticky selection (toggled by tap) — uncontrolled mode only
  int? _hover; // transient selection (pointer hover)

  bool get _controlled => widget.onSelectionChanged != null;
  int? get _sticky => _controlled ? widget.selectedIndex : _tapped;
  int? get _active => _hover ?? _sticky;

  List<DonutSegment> get _shown {
    final double total = widget.segments
        .fold<double>(0, (double s, DonutSegment e) => s + e.value);
    return total > 0 ? widget.segments : const <DonutSegment>[];
  }

  /// Which slice (if any) sits under [local]; null when outside the ring.
  int? _hitTest(Offset local) {
    final List<DonutSegment> segs = _shown;
    if (segs.isEmpty) return null;
    final double c = widget.size / 2;
    final double dx = local.dx - c;
    final double dy = local.dy - c;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double r = (widget.size - widget.thickness) / 2;
    if (dist < r - widget.thickness / 2 || dist > r + widget.thickness / 2) {
      return null;
    }
    final double total =
        segs.fold<double>(0, (double s, DonutSegment e) => s + e.value);
    double rel = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi);
    if (rel < 0) rel += 2 * math.pi;
    double acc = 0;
    for (int i = 0; i < segs.length; i++) {
      final double sweep = (segs[i].value / total) * (2 * math.pi);
      if (rel >= acc && rel < acc + sweep) return i;
      acc += sweep;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<DonutSegment> segs = _shown;
    final int? active = (_active != null && _active! < segs.length) ? _active : null;

    Widget? center;
    if (active != null) {
      final DonutSegment seg = segs[active];
      center = _CenterLabel(
        top: seg.label,
        bottom: seg.valueLabel,
        topColor: seg.color,
      );
    } else if (widget.centerTop != null || widget.centerBottom != null) {
      center = _CenterLabel(top: widget.centerTop, bottom: widget.centerBottom);
    }

    return MouseRegion(
      onHover: (e) {
        final int? hit = _hitTest(e.localPosition);
        if (hit != _hover) setState(() => _hover = hit);
      },
      onExit: (_) {
        if (_hover != null) setState(() => _hover = null);
      },
      child: GestureDetector(
        onTapDown: (d) {
          final int? hit = _hitTest(d.localPosition);
          if (hit == null) return;
          final int? next = _sticky == hit ? null : hit;
          if (_controlled) {
            widget.onSelectionChanged!(next);
          } else {
            setState(() => _tapped = next);
          }
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _DonutPainter(
              segments: segs,
              thickness: widget.thickness,
              selected: active,
              track: widget.trackColor ??
                  Theme.of(context).dividerColor.withValues(alpha: 0.25),
            ),
            child: center == null ? null : Center(child: center),
          ),
        ),
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({this.top, this.bottom, this.topColor});
  final String? top;
  final String? bottom;
  final Color? topColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (top != null)
            Text(top!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: topColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          if (bottom != null)
            Text(bottom!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.track,
    this.selected,
  });

  final List<DonutSegment> segments;
  final double thickness;
  final Color track;
  final int? selected;

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
    for (int i = 0; i < segments.length; i++) {
      final DonutSegment seg = segments[i];
      final double sweep = (seg.value / total) * (2 * math.pi);
      if (sweep <= 0) continue;
      final bool dim = selected != null && selected != i;
      final double stroke = selected == i ? thickness + 4 : thickness;
      final Paint p = Paint()
        ..color = seg.color.withValues(alpha: dim ? 0.30 : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
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
      old.selected != selected ||
      old.track != track;
}
