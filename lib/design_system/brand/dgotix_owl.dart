import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// What the owl is doing, set by the screen it lives on.
enum OwlMood {
  /// Resting: blinks now and then, watches the user's finger or pointer.
  idle,

  /// Looks down at what the user is typing.
  reading,

  /// Looks up, as if thinking.
  thinking,

  /// Smiles and hops (an answer arrived).
  happy,

  /// Tilts its head and squints (something went wrong).
  confused,
}

/// The DGOTIX owl: the mascot of DGOTIX AI, with the logo's "DG" drawn on its
/// eyes (the swoops are its brows, the D and the G frame its eyes).
///
/// Drawn in code (no image, no network), tinted with the theme's brand color.
/// [headOnly] gives the icon form; [animate] the waiting form, which sways,
/// looks around, blinks and twinkles. [smiling] closes its eyes in a happy
/// smile (^ ^) while nobody is pointing nearby. An [interactive] owl blinks
/// now and then, follows the user's finger or pointer with its eyes, and
/// hops happily when tapped; [mood] lets the screen show what it is doing.
/// It holds still when the system asks for reduced motion.
class DgotixOwl extends StatefulWidget {
  const DgotixOwl({
    super.key,
    this.size = 48,
    this.headOnly = false,
    this.animate = false,
    this.smiling = false,
    this.interactive = false,
    this.mood = OwlMood.idle,
  });

  /// Rendered height; the width follows the owl's proportions.
  final double size;
  final bool headOnly;
  final bool animate;
  final bool smiling;
  final bool interactive;
  final OwlMood mood;

  @override
  State<DgotixOwl> createState() => _DgotixOwlState();
}

class _DgotixOwlState extends State<DgotixOwl> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );
  final math.Random _rng = math.Random();
  Timer? _blinkTimer;
  Timer? _gazeTimer;
  bool _routed = false;
  bool _still = false;

  /// Where the user's finger or pointer is, as a direction (length <= 1).
  Offset _gaze = Offset.zero;
  bool _watching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DgotixOwl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (widget.mood == OwlMood.happy &&
        oldWidget.mood != OwlMood.happy &&
        !_still) {
      _hop.forward(from: 0);
    }
  }

  void _sync() {
    _still = MediaQuery.disableAnimationsOf(context);
    final bool run = widget.animate && !_still;
    if (run && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!run && _loop.isAnimating) {
      _loop
        ..stop()
        ..value = 0;
    }
    final bool alive = widget.interactive && !_still;
    if (alive && !_routed) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      _routed = true;
      _scheduleBlink();
    } else if (!alive && _routed) {
      _stopLife();
    }
  }

  void _stopLife() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _routed = false;
    _blinkTimer?.cancel();
    _gazeTimer?.cancel();
    _watching = false;
    _gaze = Offset.zero;
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer =
        Timer(Duration(milliseconds: 2200 + _rng.nextInt(3200)), () async {
      if (!mounted) return;
      await _blink.forward(from: 0);
      if (!mounted) return;
      await _blink.reverse();
      if (mounted && _routed) _scheduleBlink();
    });
  }

  /// Every pointer event in the app: the owl turns its eyes toward it.
  void _onPointer(PointerEvent e) {
    if (e is! PointerHoverEvent &&
        e is! PointerMoveEvent &&
        e is! PointerDownEvent) {
      return;
    }
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final Offset center = box.localToGlobal(box.size.center(Offset.zero));
    final Offset d = e.position - center;
    final double dist = d.distance;
    final Offset g = dist < 1
        ? Offset.zero
        : d / dist * math.min(1, dist / (widget.size * 1.5));
    _gazeTimer?.cancel();
    _gazeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _watching = false;
          _gaze = Offset.zero;
        });
      }
    });
    if (!_watching || (g - _gaze).distance > 0.04) {
      setState(() {
        _watching = true;
        _gaze = g;
      });
    }
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (!_still) _hop.forward(from: 0);
  }

  Offset get _targetLook => switch (widget.mood) {
        OwlMood.reading => const Offset(0, 0.85),
        OwlMood.thinking => const Offset(0.5, -0.6),
        OwlMood.confused => const Offset(-0.6, 0.1),
        _ => _watching ? _gaze : Offset.zero,
      };

  @override
  void dispose() {
    if (_routed) _stopLife();
    _loop.dispose();
    _hop.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color brand = context.dsColors.brand;
    final Rect view =
        widget.headOnly ? _OwlPainter.headView : _OwlPainter.fullView;
    final Widget owl = SizedBox(
      width: widget.size * view.width / view.height,
      height: widget.size,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _targetLook),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (BuildContext context, Offset look, _) => AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_loop, _hop, _blink]),
          builder: (BuildContext context, _) {
            final bool hopping = _hop.isAnimating;
            final bool smile = widget.mood == OwlMood.happy ||
                hopping ||
                (widget.smiling && !_watching && widget.mood == OwlMood.idle);
            final double blink = smile ? 1 : _blink.value;
            final bool confused = widget.mood == OwlMood.confused && !smile;
            return CustomPaint(
              painter: _OwlPainter(
                t: _loop.value,
                moving: _loop.isAnimating,
                brand: brand,
                headOnly: widget.headOnly,
                look: look,
                blinkLeft: blink,
                blinkRight: confused ? math.max(blink, 0.45) : blink,
                hop: hopping ? _hop.value : 0,
                tilt: confused ? -8 : 0,
              ),
            );
          },
        ),
      ),
    );
    return ExcludeSemantics(
      child: widget.interactive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: _onTap, child: owl)
          : owl,
    );
  }
}

/// Paints the owl on a 1600 x 1700 canvas, scaled to fit.
class _OwlPainter extends CustomPainter {
  _OwlPainter({
    required this.t,
    required this.moving,
    required this.brand,
    required this.headOnly,
    required this.look,
    required this.blinkLeft,
    required this.blinkRight,
    required this.hop,
    required this.tilt,
  });

  final double t;
  final bool moving;
  final Color brand;
  final bool headOnly;
  final Offset look;
  final double blinkLeft;
  final double blinkRight;
  final double hop;
  final double tilt;

  static const Rect fullView = Rect.fromLTWH(0, 0, 1600, 1700);
  static const Rect headView = Rect.fromLTRB(120, 40, 1480, 1240);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _pupil = Color(0xFF0B1B33);
  static const Color _amber = Color(0xFFF5A623);
  static const Color _cheek = Color(0xFFFF96AF);

  static final Path _d = _letterD();
  static final Path _g = _letterG();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect view = headOnly ? headView : fullView;
    final double s =
        math.min(size.width / view.width, size.height / view.height);
    canvas
      ..save()
      ..translate((size.width - view.width * s) / 2,
          (size.height - view.height * s) / 2)
      ..scale(s)
      ..translate(-view.left, -view.top);

    final Color dark = Color.lerp(brand, const Color(0xFF000000), 0.18)!;
    final Color belly = Color.lerp(brand, _white, 0.55)!;
    final Color feather = Color.lerp(brand, _white, 0.3)!;
    Paint fill(Color c) => Paint()..color = c;

    // The waiting loop: a gentle bob and sway, a look up to the right (as if
    // thinking), a happy blink, a look to the left, a half blink.
    final int frame = (t * 48).floor();
    double bob = moving ? 26 * math.sin(t * 4 * math.pi) : 0;
    double turn = moving ? 6 * math.sin(t * 2 * math.pi) : tilt;
    double spark = moving ? 0.55 + 0.45 * math.sin(t * 3 * math.pi).abs() : 1;
    Offset look = this.look;
    double blinkL = blinkLeft;
    double blinkR = blinkRight;
    if (moving) {
      look = Offset.zero;
      if (frame >= 10 && frame < 22) look = const Offset(0.5, -0.6);
      if (frame >= 26 && frame < 36) look = const Offset(-0.5, -0.3);
      if (frame == 24 || frame == 25) blinkL = blinkR = 1;
      if (frame == 42) blinkL = blinkR = 0.6;
    }
    // A happy hop: up and down once, the sparkle swelling at the top.
    if (hop > 0) {
      final double h = math.sin(hop * math.pi);
      bob -= 150 * h;
      spark = 1 + 0.5 * h;
      turn += 5 * math.sin(hop * 2 * math.pi);
    }

    canvas
      ..translate(0, bob)
      ..translate(800, 1580)
      ..rotate(-turn * math.pi / 180)
      ..translate(-800, -1580);

    if (!headOnly) {
      // Feet, body, belly feathers, wings.
      for (final int sx in const <int>[-1, 1]) {
        final double fx = 800.0 + sx * 140;
        for (final int k in const <int>[-1, 0, 1]) {
          canvas.drawOval(
              Rect.fromLTRB(fx + k * 42 - 30, 1522, fx + k * 42 + 30, 1584),
              fill(_amber));
        }
      }
      canvas
        ..drawOval(const Rect.fromLTRB(420, 1020, 1180, 1580), fill(brand))
        ..drawOval(const Rect.fromLTRB(550, 1140, 1050, 1560), fill(belly));
      final Paint stroke = Paint()
        ..color = feather
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13;
      const List<(double, List<double>)> rows = <(double, List<double>)>[
        (1230, <double>[-110, 0, 110]),
        (1330, <double>[-55, 55]),
        (1430, <double>[-110, 0, 110]),
      ];
      for (final (double y, List<double> xs) in rows) {
        for (final double x in xs) {
          canvas.drawArc(Rect.fromLTRB(758 + x, y - 22, 842 + x, y + 22),
              _rad(20), _rad(140), false, stroke);
        }
      }
      canvas
        ..drawOval(const Rect.fromLTRB(330, 1080, 530, 1470), fill(dark))
        ..drawOval(const Rect.fromLTRB(1070, 1080, 1270, 1470), fill(dark));
    }

    // Ear tufts, head, cheeks.
    canvas
      ..drawPath(
          Path()
            ..moveTo(320, 320)
            ..lineTo(210, 80)
            ..lineTo(540, 190)
            ..close(),
          fill(brand))
      ..drawPath(
          Path()
            ..moveTo(1280, 320)
            ..lineTo(1390, 80)
            ..lineTo(1060, 190)
            ..close(),
          fill(brand))
      ..drawOval(const Rect.fromLTRB(160, 100, 1440, 1220), fill(brand))
      ..drawOval(const Rect.fromLTRB(285, 938, 455, 1022), fill(_cheek))
      ..drawOval(const Rect.fromLTRB(1145, 938, 1315, 1022), fill(_cheek));

    // Eye whites: round on the left, the G's bowl on the right.
    if (blinkL < 0.99) {
      canvas.drawCircle(const Offset(585, 775), 150, fill(_white));
    }
    if (blinkR < 0.99) {
      canvas.drawOval(const Rect.fromLTRB(815, 640, 1060, 940), fill(_white));
    }

    // The logo's D and G (SVG units) over the eyes.
    canvas
      ..save()
      ..translate(-939, -784)
      ..scale(4)
      ..drawPath(_d, fill(_white))
      ..drawPath(_g, fill(_white))
      ..restore();

    // Pupils (or happy closed eyes).
    for (final (Offset c, double r, double blink) in <(Offset, double, double)>[
      (const Offset(585, 775), 95, blinkL),
      (const Offset(940, 790), 80, blinkR),
    ]) {
      final Offset p = c + look * (r * 0.3);
      if (blink >= 0.99) {
        canvas.drawArc(
            Rect.fromLTRB(p.dx - r, p.dy - r * 0.7, p.dx + r, p.dy + r * 0.7),
            _rad(200),
            _rad(140),
            false,
            Paint()
              ..color = _pupil
              ..style = PaintingStyle.stroke
              ..strokeWidth = 26);
        continue;
      }
      final double h = r * (1 - blink);
      canvas.drawOval(
          Rect.fromLTRB(p.dx - r, p.dy - h, p.dx + r, p.dy + h), fill(_pupil));
      if (blink < 0.5) {
        canvas
          ..drawOval(
              Rect.fromLTRB(p.dx + r * 0.1, p.dy - r * 0.7, p.dx + r * 0.62,
                  p.dy - r * 0.18),
              fill(_white))
          ..drawOval(
              Rect.fromLTRB(p.dx - r * 0.55, p.dy + r * 0.25, p.dx - r * 0.3,
                  p.dy + r * 0.5),
              fill(_white));
      }
    }

    // Beak.
    canvas.drawPath(
        Path()
          ..moveTo(744, 970)
          ..lineTo(840, 970)
          ..lineTo(792, 1050)
          ..close(),
        fill(_amber));

    // The AI sparkle.
    if (!headOnly) {
      _star(canvas, const Offset(1400, 130), 110 * spark, fill(_amber));
      _star(canvas, const Offset(1530, 300), 48 * (1.6 - spark), fill(_amber));
    }
    canvas.restore();
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final Path p = Path();
    for (int k = 0; k < 8; k++) {
      final double a = k * math.pi / 4 - math.pi / 2;
      final double rr = k.isEven ? r : r * 0.28;
      final Offset o = c + Offset(rr * math.cos(a), rr * math.sin(a));
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(p..close(), paint);
  }

  @override
  bool shouldRepaint(_OwlPainter old) =>
      old.t != t ||
      old.moving != moving ||
      old.brand != brand ||
      old.headOnly != headOnly ||
      old.look != look ||
      old.blinkLeft != blinkLeft ||
      old.blinkRight != blinkRight ||
      old.hop != hop ||
      old.tilt != tilt;

  // Paths copied from assets/brand/dgotix-logo.svg (the D and the G).
  static Path _letterD() => Path()
    ..moveTo(405.145, 318.77)
    ..cubicTo(376.923, 304.932, 354.113, 297.669, 324.145, 291.77)
    ..cubicTo(294.178, 285.872, 321.14, 315.794, 321.14, 315.794)
    ..lineTo(364.14, 328.294)
    ..cubicTo(396.605, 341.748, 413.494, 354.47, 420.645, 383.77)
    ..cubicTo(421.696, 410.083, 414.349, 423.252, 394.645, 435.27)
    ..cubicTo(374.942, 447.288, 394.645, 463.27, 394.645, 463.27)
    ..cubicTo(411.221, 455.234, 420.137, 448.396, 435.645, 433.77)
    ..lineTo(437.145, 349.77)
    ..cubicTo(424.71, 333.752, 421.145, 328.27, 405.145, 318.77)
    ..close();

  static Path _letterG() => Path()
    ..moveTo(547.646, 316.27)
    ..cubicTo(572.237, 310.719, 547.646, 291.77, 547.646, 291.77)
    ..cubicTo(523.484, 295.794, 510.024, 299.326, 486.146, 307.77)
    ..cubicTo(461.334, 317.066, 449.66, 327.168, 433.646, 349.77)
    ..lineTo(433.646, 390.77)
    ..lineTo(433.646, 433.27)
    ..cubicTo(448.661, 452.847, 463.688, 463.095, 488.146, 464.27)
    ..cubicTo(507.204, 465.186, 519.445, 460.804, 534.646, 449.27)
    ..cubicTo(550.525, 437.222, 558.485, 425.864, 562.146, 406.27)
    ..cubicTo(563.938, 396.673, 562.146, 381.27, 562.146, 381.27)
    ..cubicTo(562.146, 381.27, 497.395, 353.892, 488.146, 381.27)
    ..cubicTo(485.021, 390.52, 488.146, 406.27, 488.146, 406.27)
    ..lineTo(534.646, 406.27)
    ..cubicTo(523.214, 431.674, 501.697, 443.638, 477.646, 436.27)
    ..cubicTo(453.671, 428.926, 443.371, 404.559, 447.146, 379.77)
    ..cubicTo(450.58, 357.215, 465.392, 344.58, 486.146, 333.77)
    ..cubicTo(506.899, 322.96, 547.646, 316.27, 547.646, 316.27)
    ..close();
}
