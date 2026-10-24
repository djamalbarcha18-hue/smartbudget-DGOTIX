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

  /// Dances happily: hops to a beat, flaps its wings, smiles (signing in).
  dancing,

  /// Frowns, blushes red and shakes its head (a wrong password).
  angry,
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
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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
    if (widget.mood == OwlMood.angry &&
        oldWidget.mood != OwlMood.angry &&
        !_still) {
      _shake.forward(from: 0);
    }
  }

  void _sync() {
    _still = MediaQuery.disableAnimationsOf(context);
    final bool run =
        (widget.animate || widget.mood == OwlMood.dancing) && !_still;
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
        OwlMood.angry => const Offset(0, 0.15),
        OwlMood.dancing => Offset.zero,
        _ => _watching ? _gaze : Offset.zero,
      };

  @override
  void dispose() {
    if (_routed) _stopLife();
    _loop.dispose();
    _hop.dispose();
    _blink.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _OwlColors colors = _OwlColors.of(context.dsColors);
    final Rect view =
        widget.headOnly ? _OwlPainter.headView : _OwlPainter.fullView;
    final Widget owl = SizedBox(
      width: widget.size * view.width / view.height,
      height: widget.size,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _targetLook),
        duration: _still ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (BuildContext context, Offset look, _) => AnimatedBuilder(
          animation:
              Listenable.merge(<Listenable>[_loop, _hop, _blink, _shake]),
          builder: (BuildContext context, _) {
            final bool hopping = _hop.isAnimating;
            final bool dancing = widget.mood == OwlMood.dancing;
            final bool smile = widget.mood == OwlMood.happy ||
                dancing ||
                hopping ||
                (widget.smiling && !_watching && widget.mood == OwlMood.idle);
            final double blink = smile ? 1 : _blink.value;
            final bool confused = widget.mood == OwlMood.confused && !smile;
            return CustomPaint(
              painter: _OwlPainter(
                t: _loop.value,
                moving: _loop.isAnimating,
                colors: colors,
                headOnly: widget.headOnly,
                look: look,
                blinkLeft: blink,
                blinkRight: confused ? math.max(blink, 0.45) : blink,
                hop: hopping ? _hop.value : 0,
                tilt: confused ? -8 : 0,
                dance: dancing,
                angry: widget.mood == OwlMood.angry && !smile,
                shake: _shake.isAnimating ? _shake.value : 0,
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

/// The owl's colors for a theme: the body follows the brand color; the
/// logo and eyes are always white; the rest follows how light that color is.
/// A light brand (Black Gold's gold) takes dark-brown pupils, a bronze beak,
/// a pale-gold sparkle and no blush; the others navy pupils, an amber beak
/// and sparkle, and pink cheeks.
@immutable
class _OwlColors {
  const _OwlColors({
    required this.body,
    required this.wing,
    required this.belly,
    required this.feather,
    required this.mark,
    required this.eye,
    required this.pupil,
    required this.beak,
    required this.star,
    required this.cheek,
  });

  factory _OwlColors.of(DsColors c) {
    const Color white = Color(0xFFFFFFFF);
    const Color black = Color(0xFF000000);
    final Color b = c.brand;
    final bool lightBrand = b.computeLuminance() > 0.35;
    return _OwlColors(
      body: b,
      wing: Color.lerp(b, black, 0.18)!,
      belly: Color.lerp(b, white, 0.55)!,
      feather: Color.lerp(b, white, 0.3)!,
      mark: white,
      eye: white,
      pupil: lightBrand ? const Color(0xFF1A1610) : const Color(0xFF0B1B33),
      beak: lightBrand ? Color.lerp(b, black, 0.55)! : const Color(0xFFF5A623),
      star: lightBrand ? c.brandStrong : const Color(0xFFF5A623),
      cheek: lightBrand ? null : const Color(0xFFFF96AF),
    );
  }

  final Color body;
  final Color wing;
  final Color belly;
  final Color feather;
  final Color mark;
  final Color eye;
  final Color pupil;
  final Color beak;
  final Color star;
  final Color? cheek;

  @override
  bool operator ==(Object other) =>
      other is _OwlColors &&
      other.body == body &&
      other.mark == mark &&
      other.eye == eye &&
      other.pupil == pupil &&
      other.beak == beak &&
      other.star == star &&
      other.cheek == cheek;

  @override
  int get hashCode => Object.hash(body, mark, eye, pupil, beak, star, cheek);
}

/// Paints the owl on a 1600 x 1700 canvas, scaled to fit.
class _OwlPainter extends CustomPainter {
  _OwlPainter({
    required this.t,
    required this.moving,
    required this.colors,
    required this.headOnly,
    required this.look,
    required this.blinkLeft,
    required this.blinkRight,
    required this.hop,
    required this.tilt,
    required this.dance,
    required this.angry,
    required this.shake,
  });

  final double t;
  final bool moving;
  final _OwlColors colors;
  final bool headOnly;
  final Offset look;
  final double blinkLeft;
  final double blinkRight;
  final double hop;
  final double tilt;
  final bool dance;
  final bool angry;
  final double shake;

  static const Rect fullView = Rect.fromLTWH(0, 0, 1600, 1700);
  static const Rect headView = Rect.fromLTRB(120, 40, 1480, 1240);

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

    final _OwlColors k = colors;
    Paint fill(Color c) => Paint()..color = c;

    double bob = 0;
    double turn = tilt;
    double spark = 1;
    double flap = 0;
    Offset look = this.look;
    double blinkL = blinkLeft;
    double blinkR = blinkRight;
    if (moving && dance) {
      // The dance: four bouncy beats a loop, swaying side to side, wings up
      // on every beat, the sparkle pulsing along.
      final double beat = math.sin(t * 4 * math.pi).abs();
      bob = -70 * beat;
      turn = 9 * math.sin(t * 4 * math.pi);
      flap = 32 * beat;
      spark = 0.6 + 0.5 * beat;
    } else if (moving) {
      // The waiting loop: a gentle bob and sway, a look up to the right (as
      // if thinking), a happy blink, a look to the left, a half blink.
      final int frame = (t * 48).floor();
      bob = 26 * math.sin(t * 4 * math.pi);
      turn = 6 * math.sin(t * 2 * math.pi);
      spark = 0.55 + 0.45 * math.sin(t * 3 * math.pi).abs();
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
    // An angry shake of the head: quick, fading out.
    if (shake > 0) turn += 9 * math.sin(shake * 6 * math.pi) * (1 - shake);

    canvas
      ..translate(0, bob)
      // The full owl sways on its feet; the head alone turns on its center.
      ..translate(800, headOnly ? 660 : 1580)
      ..rotate(-turn * math.pi / 180)
      ..translate(-800, headOnly ? -660 : -1580);

    if (!headOnly) {
      // Feet, body, belly feathers, wings.
      for (final int sx in const <int>[-1, 1]) {
        final double fx = 800.0 + sx * 140;
        for (final int toe in const <int>[-1, 0, 1]) {
          canvas.drawOval(
              Rect.fromLTRB(fx + toe * 42 - 30, 1522, fx + toe * 42 + 30, 1584),
              fill(k.beak));
        }
      }
      canvas
        ..drawOval(const Rect.fromLTRB(420, 1020, 1180, 1580), fill(k.body))
        ..drawOval(const Rect.fromLTRB(550, 1140, 1050, 1560), fill(k.belly));
      final Paint stroke = Paint()
        ..color = k.feather
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
      // Wings hang from the shoulders and lift outward when dancing.
      for (final (Offset shoulder, Rect wing, double sign)
          in <(Offset, Rect, double)>[
        (const Offset(480, 1120), const Rect.fromLTRB(330, 1080, 530, 1470), 1),
        (
          const Offset(1120, 1120),
          const Rect.fromLTRB(1070, 1080, 1270, 1470),
          -1
        ),
      ]) {
        canvas
          ..save()
          ..translate(shoulder.dx, shoulder.dy)
          ..rotate(sign * _rad(flap))
          ..translate(-shoulder.dx, -shoulder.dy)
          ..drawOval(wing, fill(k.wing))
          ..restore();
      }
    }

    // Ear tufts, head, cheeks.
    canvas
      ..drawPath(
          Path()
            ..moveTo(320, 320)
            ..lineTo(210, 80)
            ..lineTo(540, 190)
            ..close(),
          fill(k.body))
      ..drawPath(
          Path()
            ..moveTo(1280, 320)
            ..lineTo(1390, 80)
            ..lineTo(1060, 190)
            ..close(),
          fill(k.body))
      ..drawOval(const Rect.fromLTRB(160, 100, 1440, 1220), fill(k.body));
    // An angry owl goes red in the face.
    final Color? cheek = angry ? const Color(0xFFFF5A5F) : k.cheek;
    if (cheek != null) {
      canvas
        ..drawOval(const Rect.fromLTRB(285, 938, 455, 1022), fill(cheek))
        ..drawOval(const Rect.fromLTRB(1145, 938, 1315, 1022), fill(cheek));
    }

    // Eye whites: round on the left, the G's bowl on the right.
    if (blinkL < 0.99) {
      canvas.drawCircle(const Offset(585, 775), 150, fill(k.eye));
    }
    if (blinkR < 0.99) {
      canvas.drawOval(const Rect.fromLTRB(815, 640, 1060, 940), fill(k.eye));
    }

    // The logo's D and G (SVG units) over the eyes.
    canvas
      ..save()
      ..translate(-939, -784)
      ..scale(4)
      ..drawPath(_d, fill(k.mark))
      ..drawPath(_g, fill(k.mark))
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
              ..color = k.pupil
              ..style = PaintingStyle.stroke
              ..strokeWidth = 26);
        continue;
      }
      final double h = r * (1 - blink);
      canvas.drawOval(
          Rect.fromLTRB(p.dx - r, p.dy - h, p.dx + r, p.dy + h), fill(k.pupil));
      if (blink < 0.5) {
        canvas
          ..drawOval(
              Rect.fromLTRB(p.dx + r * 0.1, p.dy - r * 0.7, p.dx + r * 0.62,
                  p.dy - r * 0.18),
              fill(k.eye))
          ..drawOval(
              Rect.fromLTRB(p.dx - r * 0.55, p.dy + r * 0.25, p.dx - r * 0.3,
                  p.dy + r * 0.5),
              fill(k.eye));
      }
    }

    // Angry brows: lids slanting down toward the beak, under the logo.
    if (angry) {
      canvas
        ..drawPath(
            Path()
              ..moveTo(400, 590)
              ..lineTo(775, 590)
              ..lineTo(775, 765)
              ..lineTo(400, 665)
              ..close(),
            fill(k.body))
        ..drawPath(
            Path()
              ..moveTo(795, 600)
              ..lineTo(1080, 600)
              ..lineTo(1080, 690)
              ..lineTo(795, 785)
              ..close(),
            fill(k.body))
        ..save()
        ..translate(-939, -784)
        ..scale(4)
        ..drawPath(_d, fill(k.mark))
        ..drawPath(_g, fill(k.mark))
        ..restore();
      // The anger mark by its ear.
      final Paint vein = Paint()
        ..color = const Color(0xFFE5484D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round;
      const Offset at = Offset(1330, 300);
      for (final (double sx, double sy) in const <(double, double)>[
        (1, 1),
        (1, -1),
        (-1, 1),
        (-1, -1),
      ]) {
        final Offset c = at + Offset(sx * 62, sy * 62);
        final double toward = math.atan2(-sy, -sx);
        canvas.drawArc(Rect.fromCircle(center: c, radius: 50),
            toward - math.pi / 4, math.pi / 2, false, vein);
      }
    }

    // Beak.
    canvas.drawPath(
        Path()
          ..moveTo(744, 970)
          ..lineTo(840, 970)
          ..lineTo(792, 1050)
          ..close(),
        fill(k.beak));

    // The AI sparkle.
    if (!headOnly && !angry) {
      _star(canvas, const Offset(1400, 130), 110 * spark, fill(k.star));
      _star(canvas, const Offset(1530, 300), 48 * (1.6 - spark), fill(k.star));
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
      old.colors != colors ||
      old.headOnly != headOnly ||
      old.look != look ||
      old.blinkLeft != blinkLeft ||
      old.blinkRight != blinkRight ||
      old.hop != hop ||
      old.tilt != tilt ||
      old.dance != dance ||
      old.angry != angry ||
      old.shake != shake;

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
