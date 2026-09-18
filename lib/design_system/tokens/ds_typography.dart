import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens.
///
/// Tajawal is used as the primary family: it renders Arabic beautifully and
/// keeps Latin digits/letters clean, so a single family works for both
/// LTR (English) and RTL (Arabic) without a font swap on locale change.
abstract final class DsTypography {
  static TextTheme textTheme({
    required Color primary,
    required Color muted,
  }) {
    final TextTheme base = GoogleFonts.tajawalTextTheme();

    TextStyle p(TextStyle? s, double size, FontWeight w,
        {Color? color, double? height, double? spacing}) {
      return (s ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: w,
        color: color ?? primary,
        height: height,
        letterSpacing: spacing,
      );
    }

    return base.copyWith(
      displaySmall: p(base.displaySmall, 34, FontWeight.w800, height: 1.1),
      headlineMedium: p(base.headlineMedium, 26, FontWeight.w700, height: 1.15),
      headlineSmall: p(base.headlineSmall, 22, FontWeight.w700),
      titleLarge: p(base.titleLarge, 18, FontWeight.w700),
      titleMedium: p(base.titleMedium, 15, FontWeight.w600),
      titleSmall: p(base.titleSmall, 13, FontWeight.w600, color: muted),
      bodyLarge: p(base.bodyLarge, 15, FontWeight.w500, height: 1.5),
      bodyMedium: p(base.bodyMedium, 13.5, FontWeight.w500, height: 1.5),
      bodySmall: p(base.bodySmall, 12, FontWeight.w500, color: muted),
      labelLarge: p(base.labelLarge, 13, FontWeight.w600, spacing: 0.2),
      labelMedium: p(base.labelMedium, 11.5, FontWeight.w600, color: muted),
      labelSmall: p(base.labelSmall, 10.5, FontWeight.w600, color: muted),
    );
  }

  /// Tabular figures for financial numbers (aligned digits in tables/KPIs).
  static TextStyle mono(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
