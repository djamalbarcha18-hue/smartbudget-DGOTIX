import 'package:flutter/widgets.dart';

/// Calm motion: short, eased, once. Figures move from where they were to
/// where they are (from nothing the first time they show) and then stay;
/// nothing loops. With "reduce motion" on in the device's settings they
/// simply appear.
abstract final class DsMotion {
  /// A value changing (a figure, a tab).
  static const Duration quick = Duration(milliseconds: 220);

  /// A ring or a bar drawing itself.
  static const Duration draw = Duration(milliseconds: 650);

  static const Curve ease = Curves.easeOutCubic;

  /// True when the user asked the device for less motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or nothing when motion is reduced.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Runs a start once, the first time the widget is on screen: a chart
/// further down a page draws itself when the user scrolls to it, not
/// unseen while the page loads.
mixin DsFirstSight<T extends StatefulWidget> on State<T> {
  final List<ScrollPosition> _watched = <ScrollPosition>[];
  VoidCallback? _onSight;
  bool _seen = false;

  /// True once the widget has been on screen (its start has run).
  bool get firstSeen => _seen;

  /// Calls [start] as soon as this widget is (partly) visible.
  void whenFirstSeen(VoidCallback start) {
    _onSight = start;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  /// Every scroll this widget sits in, nearest first (a page view inside
  /// a page that scrolls down: both).
  List<ScrollableState> get _scrollables {
    final List<ScrollableState> out = <ScrollableState>[];
    ScrollableState? s = Scrollable.maybeOf(context);
    while (s != null) {
      out.add(s);
      s = Scrollable.maybeOf(s.context);
    }
    return out;
  }

  bool _visible(List<ScrollableState> scrollables) {
    final RenderObject? box = context.findRenderObject();
    if (!mounted || box is! RenderBox || !box.attached || !box.hasSize) {
      return false;
    }
    final Rect me = box.localToGlobal(Offset.zero) & box.size;
    Rect view =
        Offset.zero & (MediaQuery.maybeSizeOf(context) ?? const Size(1e5, 1e5));
    for (final ScrollableState s in scrollables) {
      final RenderObject? sBox = s.context.findRenderObject();
      if (sBox is RenderBox && sBox.hasSize) {
        view = view.intersect(sBox.localToGlobal(Offset.zero) & sBox.size);
      }
    }
    // A mark with no size yet counts by where it sits.
    return me.overlaps(view) || view.contains(me.center);
  }

  void _check() {
    if (!mounted || _onSight == null) return;
    final List<ScrollableState> scrollables = _scrollables;
    if (_visible(scrollables)) {
      final VoidCallback start = _onSight!;
      _onSight = null;
      _seen = true;
      _stopWatching();
      start();
      return;
    }
    for (final ScrollableState s in scrollables) {
      if (!_watched.contains(s.position)) {
        _watched.add(s.position..addListener(_check));
      }
    }
  }

  void _stopWatching() {
    for (final ScrollPosition p in _watched) {
      p.removeListener(_check);
    }
    _watched.clear();
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }
}

/// [value] eased in: from 0 when first on screen, then from the last value
/// to the new one. For rings and bars that fill (a score, a goal).
class DsEased extends StatefulWidget {
  const DsEased({
    super.key,
    required this.value,
    required this.builder,
    this.duration = DsMotion.draw,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  State<DsEased> createState() => _DsEasedState();
}

class _DsEasedState extends State<DsEased> with DsFirstSight<DsEased> {
  @override
  void initState() {
    super.initState();
    whenFirstSeen(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: firstSeen ? widget.value : 0),
      duration: DsMotion.of(context, widget.duration),
      curve: DsMotion.ease,
      builder: (BuildContext context, double v, _) =>
          widget.builder(context, v),
    );
  }
}
