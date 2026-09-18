import 'package:flutter/widgets.dart';

/// Responsive breakpoints (desktop-first, degrades gracefully to mobile web).
abstract final class DsBreakpoints {
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1280;

  static bool isMobile(double w) => w < mobile;
  static bool isTablet(double w) => w >= mobile && w < tablet;
  static bool isDesktop(double w) => w >= tablet;
}

/// Convenience accessor for the current form factor.
enum DsFormFactor { mobile, tablet, desktop }

extension DsFormFactorX on BuildContext {
  DsFormFactor get formFactor {
    final double w = MediaQuery.sizeOf(this).width;
    if (DsBreakpoints.isMobile(w)) return DsFormFactor.mobile;
    if (DsBreakpoints.isTablet(w)) return DsFormFactor.tablet;
    return DsFormFactor.desktop;
  }

  bool get isMobile => formFactor == DsFormFactor.mobile;
  bool get isDesktop => formFactor == DsFormFactor.desktop;
}
