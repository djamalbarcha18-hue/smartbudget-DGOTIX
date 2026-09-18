/// Spacing scale (4pt base). Use these instead of magic numbers.
abstract final class DsSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
  static const double x5l = 56;

  /// Outer page gutter (kept generous on desktop, tightens on small screens
  /// via responsive layout).
  static const double pageGutter = 24;

  /// Default gap between dashboard grid tiles.
  static const double gridGap = 16;
}
