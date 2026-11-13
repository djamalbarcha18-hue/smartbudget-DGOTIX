import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';

/// Typography tokens.
///
/// Tajawal is used as the primary family: it renders Arabic beautifully and
/// keeps Latin digits/letters clean, so a single family works for both
/// LTR (English) and RTL (Arabic) without a font swap on locale change.
/// Urdu and Persian need letters Tajawal lacks, so they get Noto Naskh Arabic
/// (Arabic script only: its digits and Latin come from Tajawal); Inter fills
/// in Latin letters Tajawal lacks (Turkish ğ ş İ).
abstract final class DsTypography {
  /// Fallback for characters missing from the primary family (pubspec fonts).
  /// Inter for Latin, Cyrillic and most currency signs; Noto Naskh for the
  /// rial and afghani signs (﷼ ؋).
  static const List<String> fallback = <String>['SbInter', 'SbNaskh'];
  static const List<String> _urduFallback = <String>['SbTajawal', 'SbInter'];

  /// The primary family for Urdu and Persian (pubspec fonts).
  static const String urduFamily = 'SbNaskh';

  static TextTheme textTheme({
    required Color primary,
    required Color muted,
    AppLang lang = AppLang.en,
  }) {
    final TextTheme base = lang.naskh
        ? ThemeData.light().textTheme.apply(fontFamily: urduFamily)
        : GoogleFonts.tajawalTextTheme();

    TextStyle p(TextStyle? s, double size, FontWeight w,
        {Color? color, double? height, double? spacing}) {
      return (s ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: w,
        color: color ?? primary,
        height: height,
        letterSpacing: spacing,
        fontFamilyFallback: lang.naskh ? _urduFallback : fallback,
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

  /// How much text and icons grow on a phone (see [DsReadable]): icons and
  /// the few fixed-size labels by this factor; the text styles to the sizes
  /// in [compact].
  static const double compactScale = 1.15;

  /// The sizes read on a phone, in logical pixels: body text 15.5–16.5,
  /// secondary text 14 and up, card titles 19–21, page titles 23. The big
  /// figures keep their size: they are clear already and wider ones would
  /// break their cards.
  static const Map<String, double> compactSizes = <String, double>{
    'displaySmall': 34,
    'headlineMedium': 26,
    'headlineSmall': 23,
    'titleLarge': 21,
    'titleMedium': 19,
    'titleSmall': 14.5,
    'bodyLarge': 16.5,
    'bodyMedium': 15.5,
    'bodySmall': 14,
    'labelLarge': 14.5,
    'labelMedium': 13,
    'labelSmall': 12.5,
  };

  /// [t] for a phone. The sizes are stored divided by [compactScale]: the
  /// phone's text scaler multiplies them back (and scales icons with them),
  /// so what is drawn is exactly [compactSizes].
  static TextTheme compact(TextTheme t) {
    TextStyle? s(TextStyle? style, String name) =>
        style?.copyWith(fontSize: compactSizes[name]! / compactScale);
    return t.copyWith(
      displaySmall: s(t.displaySmall, 'displaySmall'),
      headlineMedium: s(t.headlineMedium, 'headlineMedium'),
      headlineSmall: s(t.headlineSmall, 'headlineSmall'),
      titleLarge: s(t.titleLarge, 'titleLarge'),
      titleMedium: s(t.titleMedium, 'titleMedium'),
      titleSmall: s(t.titleSmall, 'titleSmall'),
      bodyLarge: s(t.bodyLarge, 'bodyLarge'),
      bodyMedium: s(t.bodyMedium, 'bodyMedium'),
      bodySmall: s(t.bodySmall, 'bodySmall'),
      labelLarge: s(t.labelLarge, 'labelLarge'),
      labelMedium: s(t.labelMedium, 'labelMedium'),
      labelSmall: s(t.labelSmall, 'labelSmall'),
    );
  }

  /// Tabular figures for financial numbers (aligned digits in tables/KPIs).
  static TextStyle mono(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
