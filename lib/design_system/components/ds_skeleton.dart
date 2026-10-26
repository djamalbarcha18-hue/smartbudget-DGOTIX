import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// Skeleton loading: grey shapes the size of the content that is on its way,
/// with a calm light sweeping across them.
///
/// - [DsShimmerScope] runs one animation for every bone below it; bones only
///   repaint (nothing rebuilds per frame), at most [DsShimmerScope.fps] times
///   a second. With reduced motion, once [DsShimmerScope.running] is false, or
///   with no scope above, bones stay still.
/// - Skeleton cards look like glass cards without their backdrop blur, which
///   would otherwise be redrawn on every frame of the sweep.
/// - [DsSkeleton] is what a page shows while loading: it appears only after a
///   short delay (fast loads never flash it), keeps its place in the layout
///   while hidden, announces «loading» to screen readers once, and after a
///   long wait says so and offers to try again.
/// - [DsBone], [DsSkeletonLines], [DsSkeletonTile], [DsSkeletonList],
///   [DsSkeletonCard] and [DsSkeletonChart] are the shapes.

/// The bone colours of the current theme: a little darker (or lighter, in a
/// dark theme) than the card, and the sweep a little brighter.
class DsSkeletonColors {
  const DsSkeletonColors(this.bone, this.highlight);
  final Color bone;
  final Color highlight;

  static DsSkeletonColors of(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color bone = Color.alphaBlend(
        c.textPrimary.withValues(alpha: dark ? 0.10 : 0.07), c.surface);
    final Color highlight = Color.alphaBlend(
        Colors.white.withValues(alpha: dark ? 0.07 : 0.6), bone);
    return DsSkeletonColors(bone, highlight);
  }
}

/// One calm sweep every [period] for all the bones below.
class DsShimmerScope extends StatefulWidget {
  const DsShimmerScope({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1600),
    this.running = true,
  });

  final Widget child;
  final Duration period;

  /// False stops the sweep (the bones stay still).
  final bool running;

  /// The most repaints a second: a calm sweep needs no more, and slower
  /// phones are spared half the work.
  static const int fps = 30;

  /// The sweep's progress (0→1), or null when bones should stay still.
  static ValueListenable<double>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
      ?.animation;

  @override
  State<DsShimmerScope> createState() => _DsShimmerScopeState();
}

class _DsShimmerScopeState extends State<DsShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..addListener(_step);

  /// The controller's value, moved on only once per 1/[DsShimmerScope.fps] s.
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  int get _steps =>
      (widget.period.inMilliseconds * DsShimmerScope.fps / 1000).ceil();

  void _step() {
    final int n = _steps;
    final double v = (_c.value * n).floor() / n;
    if (v != _t.value) _t.value = v;
  }

  bool get _still =>
      !widget.running ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  void _sync() {
    if (_still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DsShimmerScope old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) _c.duration = widget.period;
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _ShimmerInherited(
        animation: _still ? null : _t,
        child: widget.child,
      ),
    );
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({required this.animation, required super.child});
  final ValueListenable<double>? animation;

  @override
  bool updateShouldNotify(_ShimmerInherited old) => old.animation != animation;
}

/// A rounded grey shape in place of a piece of content.
class DsBone extends StatelessWidget {
  const DsBone({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.circle = false,
  });

  /// Null fills the width it is given.
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final DsSkeletonColors colors = DsSkeletonColors.of(context);
    return SizedBox(
      width: circle ? height : (width ?? double.infinity),
      height: height,
      child: CustomPaint(
        painter: _BonePainter(
          animation: DsShimmerScope.of(context),
          colors: colors,
          radius: circle ? height / 2 : radius,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _BonePainter extends CustomPainter {
  _BonePainter({
    required this.animation,
    required this.colors,
    required this.radius,
    required this.rtl,
  }) : super(repaint: animation);

  final ValueListenable<double>? animation;
  final DsSkeletonColors colors;
  final double radius;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect r =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final Paint p = Paint()..color = colors.bone;
    final double? t = animation?.value;
    if (t != null) {
      // A soft band, three widths of the bone wide, crossing it in the
      // reading direction.
      final double w = size.width;
      final double x = (rtl ? 1 - t : t) * 3 * w - w;
      p.shader = LinearGradient(
        colors: <Color>[colors.bone, colors.highlight, colors.bone],
        stops: const <double>[0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - w / 2, 0, w, size.height));
    }
    canvas.drawRRect(r, p);
  }

  @override
  bool shouldRepaint(_BonePainter old) =>
      old.colors.bone != colors.bone ||
      old.colors.highlight != colors.highlight ||
      old.radius != radius ||
      old.rtl != rtl ||
      old.animation != animation;
}

/// A few lines of text: the first one wider, like a title.
class DsSkeletonLines extends StatelessWidget {
  const DsSkeletonLines({super.key, this.lines = 2, this.firstWidth = 0.6});
  final int lines;
  final double firstWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth.isFinite ? box.maxWidth : 240;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < lines; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              DsBone(
                width: w * (i == 0 ? firstWidth : (i.isOdd ? 0.4 : 0.5)),
                height: i == 0 ? 13 : 10,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A list row: an icon, two lines and an amount at the end (the shape of a
/// transaction, a recurring item or a market row). [framed] puts it on the
/// same rounded surface as the real rows.
class DsSkeletonTile extends StatelessWidget {
  const DsSkeletonTile({super.key, this.height = 62, this.framed = false});
  final double height;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    const Widget row = Padding(
      padding: EdgeInsets.symmetric(horizontal: DsSpacing.md),
      child: Row(
        children: <Widget>[
          DsBone(height: 38, radius: 10, width: 38),
          SizedBox(width: DsSpacing.md),
          Expanded(child: DsSkeletonLines()),
          SizedBox(width: DsSpacing.md),
          DsBone(width: 64, height: 14),
        ],
      ),
    );
    return SizedBox(
      height: height,
      child: framed
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: context.dsColors.surface,
                borderRadius: DsRadius.brMd,
              ),
              child: row,
            )
          : row,
    );
  }
}

/// [count] list rows, [gap] apart.
class DsSkeletonList extends StatelessWidget {
  const DsSkeletonList({
    super.key,
    this.count = 6,
    this.tileHeight = 62,
    this.gap = 0,
    this.framed = false,
  });
  final int count;
  final double tileHeight;
  final double gap;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0 && gap > 0) SizedBox(height: gap),
          DsSkeletonTile(height: tileHeight, framed: framed),
        ],
      ],
    );
  }
}

/// A card: a title, a few lines and, for goals, savings and debts, a
/// progress bar.
class DsSkeletonCard extends StatelessWidget {
  const DsSkeletonCard({
    super.key,
    this.height,
    this.lines = 2,
    this.progress = false,
  });

  /// Null sizes to the content; set it to match the real card exactly.
  final double? height;
  final int lines;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Row(
          children: <Widget>[
            DsBone(height: 32, width: 32, radius: 9),
            SizedBox(width: DsSpacing.md),
            Expanded(child: DsSkeletonLines(lines: 1, firstWidth: 0.5)),
            DsBone(width: 56, height: 14),
          ],
        ),
        if (lines > 0) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          DsSkeletonLines(lines: lines, firstWidth: 0.8),
        ],
        if (progress) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          const DsBone(height: 8, radius: 4),
        ],
      ],
    );
    return _SkeletonSurface(
      child: height == null
          ? body
          : SizedBox(
              height: height! - 2 * DsSpacing.lg,
              child: ClipRect(child: body),
            ),
    );
  }
}

/// A glass card's shape, fill, border and shadow, without the backdrop blur.
class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DsGlass g = context.dsGlass;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: DsRadius.brLg,
        boxShadow: g.shadow,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[g.fillTop, g.fill],
        ),
        border: Border.all(color: g.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: child,
      ),
    );
  }
}

/// A chart card: a title and bars of a few heights along the bottom.
class DsSkeletonChart extends StatelessWidget {
  const DsSkeletonChart({super.key, this.height = 260, this.bars = 8});
  final double height;
  final int bars;

  static const List<double> _shape = <double>[
    0.45,
    0.7,
    0.55,
    0.85,
    0.4,
    0.65,
    0.75,
    0.5,
    0.6,
    0.8,
    0.35,
    0.7,
  ];

  @override
  Widget build(BuildContext context) {
    return _SkeletonSurface(
      child: SizedBox(
        height: height - 2 * DsSpacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DsBone(width: 140, height: 14),
            const SizedBox(height: DsSpacing.lg),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (int i = 0; i < bars; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: DsBone(
                          height: box.maxHeight * _shape[i % _shape.length],
                          radius: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a page shows while its content loads.
///
/// Hidden (but in place) for [delay], so a load that finishes quickly never
/// flashes; then fades in with one sweep for everything inside. After
/// [slowAfter] it adds [slowMessage] and, with [onRetry], a button.
class DsSkeleton extends StatefulWidget {
  const DsSkeleton({
    super.key,
    required this.child,
    required this.semanticsLabel,
    this.slowMessage,
    this.retryLabel,
    this.onRetry,
    this.delay = const Duration(milliseconds: 180),
    this.slowAfter = const Duration(seconds: 12),
  });

  final Widget child;
  final String semanticsLabel;
  final String? slowMessage;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Duration delay;
  final Duration slowAfter;

  @override
  State<DsSkeleton> createState() => _DsSkeletonState();
}

class _DsSkeletonState extends State<DsSkeleton> {
  bool _shown = false;
  bool _slow = false;
  Timer? _showTimer;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shown = true;
    } else {
      _showTimer = Timer(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration:
                  still ? Duration.zero : const Duration(milliseconds: 220),
              // The sweep stops once the wait is called slow.
              child: DsShimmerScope(running: !_slow, child: widget.child),
            ),
          ),
          if (_slow && widget.slowMessage != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            Text(widget.slowMessage!,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: c.textMuted)),
            if (widget.onRetry != null)
              Center(
                child: TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(widget.retryLabel ?? ''),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The skeleton of a column of cards, [count] of them.
class DsSkeletonCards extends StatelessWidget {
  const DsSkeletonCards({
    super.key,
    this.count = 3,
    this.lines = 1,
    this.progress = false,
  });
  final int count;
  final int lines;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: DsSpacing.md),
          DsSkeletonCard(lines: lines, progress: progress),
        ],
      ],
    );
  }
}
