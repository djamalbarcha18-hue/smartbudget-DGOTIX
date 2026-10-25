import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Shows a theme change as a circle growing from the button that was tapped.
///
/// The screen as it was is captured and laid over the app; the change happens
/// underneath and a widening hole in the capture reveals it. Where capturing
/// is slow (some phones' browsers) a circle of the new page colour spreads
/// instead, the theme changes under it and it fades away, so the tap never
/// waits. Without motion (reduced motion, no host) the change is just made.
abstract final class ThemeReveal {
  static _ThemeRevealHostState? _host;

  static const Duration duration = Duration(milliseconds: 560);

  /// How long a capture may take before the colour circle is used instead.
  static const Duration captureBudget = Duration(milliseconds: 180);

  /// Applies [change], growing from the centre of [from] (the tapped
  /// widget's context) or of the screen. [to] is the new theme's page colour,
  /// for the colour circle.
  static Future<void> run(BuildContext from, VoidCallback change,
      {required Color to}) async {
    final _ThemeRevealHostState? host = _host;
    final bool still = MediaQuery.maybeDisableAnimationsOf(from) ?? false;
    if (host == null || still || host.busy) {
      change();
      return;
    }
    Offset? origin;
    final RenderObject? box = from.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(box.size.center(Offset.zero));
    }
    await host.reveal(origin, change, to);
  }
}

/// Wraps the app (MaterialApp.builder) so [ThemeReveal] can capture it.
class ThemeRevealHost extends StatefulWidget {
  const ThemeRevealHost({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeRevealHost> createState() => _ThemeRevealHostState();
}

class _ThemeRevealHostState extends State<ThemeRevealHost>
    with TickerProviderStateMixin {
  final GlobalKey _boundary = GlobalKey();
  late final AnimationController _grow =
      AnimationController(vsync: this, duration: ThemeReveal.duration);
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 240));
  ui.Image? _before;
  Color? _ink;
  Offset _origin = Offset.zero;
  bool _running = false;

  bool get busy => _running;

  @override
  void initState() {
    super.initState();
    ThemeReveal._host = this;
  }

  @override
  void dispose() {
    if (ThemeReveal._host == this) ThemeReveal._host = null;
    _grow.dispose();
    _fade.dispose();
    _before?.dispose();
    super.dispose();
  }

  Future<ui.Image?> _capture() async {
    try {
      final RenderRepaintBoundary? b = _boundary.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      // At 1x: it's on screen for half a second, and a smaller image is
      // quicker to take.
      return await b?.toImage(pixelRatio: 1);
    } catch (_) {
      return null;
    }
  }

  Future<void> reveal(Offset? origin, VoidCallback change, Color to) async {
    _running = true;
    _origin = origin ?? MediaQuery.sizeOf(context).center(Offset.zero);
    final Future<ui.Image?> capture = _capture();
    final ui.Image? shot =
        await capture.timeout(ThemeReveal.captureBudget, onTimeout: () {
      // Too slow here: drop the late capture and use the colour circle.
      capture.then((ui.Image? late) => late?.dispose());
      return null;
    });
    if (!mounted) {
      shot?.dispose();
      change();
      return;
    }
    try {
      if (shot != null) {
        setState(() => _before = shot);
        change();
        await _grow.forward(from: 0);
      } else {
        _fade.value = 1;
        setState(() => _ink = to);
        await _grow.animateTo(1,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInCubic);
        change();
        await SchedulerBinding.instance.endOfFrame;
        await _fade.reverse(from: 1);
      }
    } finally {
      if (mounted) {
        setState(() {
          _before?.dispose();
          _before = null;
          _ink = null;
        });
        _grow.value = 0;
      }
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? before = _before;
    final Color? ink = _ink;
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        RepaintBoundary(key: _boundary, child: widget.child),
        if (before != null || ink != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_grow, _fade]),
                builder: (BuildContext context, _) => CustomPaint(
                  painter: before != null
                      ? _RevealPainter(
                          image: before,
                          origin: _origin,
                          t: Curves.easeInOutCubic.transform(_grow.value),
                        )
                      : _InkPainter(
                          color: ink!,
                          origin: _origin,
                          t: _grow.value,
                          opacity: _fade.value,
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The distance from [origin] to the farthest corner of [size].
double _reach(Size size, Offset origin) => <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((Offset c) => (c - origin).distance).reduce(math.max);

/// The old screen, with a hole of the new one growing from [origin] until it
/// reaches the farthest corner.
class _RevealPainter extends CustomPainter {
  _RevealPainter({required this.image, required this.origin, required this.t});

  final ui.Image image;
  final Offset origin;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect all = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(all)
      ..addOval(
          Rect.fromCircle(center: origin, radius: _reach(size, origin) * t)));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      all,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.t != t || old.image != image || old.origin != origin;
}

/// A circle of the new page colour growing from [origin], then fading.
class _InkPainter extends CustomPainter {
  _InkPainter({
    required this.color,
    required this.origin,
    required this.t,
    required this.opacity,
  });

  final Color color;
  final Offset origin;
  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(origin, _reach(size, origin) * t,
        Paint()..color = color.withValues(alpha: color.a * opacity));
  }

  @override
  bool shouldRepaint(_InkPainter old) =>
      old.t != t ||
      old.opacity != opacity ||
      old.color != color ||
      old.origin != origin;
}
