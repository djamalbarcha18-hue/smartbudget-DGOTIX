import 'package:flutter/material.dart';

/// Central registry for DGOTIX brand assets.
///
/// The two official SVGs live in `assets/brand/` (byte-identical copies of the
/// repository-root originals — the logos are never redrawn or recolored):
///   • dgotix-logo.svg       → COLORED  → used in LIGHT mode / light surfaces
///   • dgotix-logo-mono.svg  → GRAY     → used in DARK mode / dark surfaces
///
/// Everything references the logo through this class, so swapping files or
/// paths later is a one-line change.
abstract final class BrandAssets {
  static const String _base = 'assets/brand';

  /// Colored logo (DGOTIX blue) — for light backgrounds.
  static const String dgotixColored = '$_base/dgotix-logo.svg';

  /// Monochrome/gray logo — for dark backgrounds.
  static const String dgotixMono = '$_base/dgotix-logo-mono.svg';

  /// Returns the correct logo for the active brightness so it swaps
  /// automatically on theme change (no reload).
  static String dgotixFor(Brightness brightness) =>
      brightness == Brightness.dark ? dgotixMono : dgotixColored;
}
