import 'package:flutter/material.dart';

/// DGOTIX Design System — semantic color tokens.
///
/// Exposed as a [ThemeExtension] so every widget reads colors from the active
/// theme (`Theme.of(context).extension<DsColors>()!`) instead of hardcoding hex
/// values. This keeps the palette swappable from a single place and makes the
/// system reusable across future DGOTIX products.
///
/// Semantic mapping is inherited from the existing SmartBudget identity:
///   income / growth  -> emerald  (#10B981)
///   expense / down   -> red      (#EF4444)
///   saving / accent  -> blue     (#3B82F6) / cyan (#06B6D4)
///   brand primary    -> DGOTIX blue (#1680F7, extracted from the official logo)
@immutable
class DsColors extends ThemeExtension<DsColors> {
  const DsColors({
    required this.brand,
    required this.brandStrong,
    required this.income,
    required this.expense,
    required this.saving,
    required this.net,
    required this.warning,
    required this.bgPage,
    required this.bgElevated,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.onBrand,
    required this.shadow,
  });

  /// DGOTIX brand blue — used as an accent, sparingly (per brand guidelines).
  final Color brand;
  final Color brandStrong;

  /// Financial semantics (must stay consistent with SmartBudget logic).
  final Color income;
  final Color expense;
  final Color saving;
  final Color net;
  final Color warning;

  /// Surfaces.
  final Color bgPage;
  final Color bgElevated;
  final Color surface;
  final Color surfaceMuted;

  /// Lines.
  final Color border;
  final Color borderStrong;

  /// Text.
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;

  /// On-brand foreground (text/icon over [brand]).
  final Color onBrand;

  /// Ambient shadow color.
  final Color shadow;

  /// Premium dark experience (primary theme).
  static const DsColors dark = DsColors(
    brand: Color(0xFF1680F7),
    brandStrong: Color(0xFF3B93FF),
    income: Color(0xFF10B981),
    expense: Color(0xFFEF4444),
    saving: Color(0xFF3B82F6),
    net: Color(0xFF06B6D4),
    warning: Color(0xFFF59E0B),
    bgPage: Color(0xFF0B1120),
    bgElevated: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceMuted: Color(0xFF172033),
    border: Color(0x1AFFFFFF), // white @ 10%
    borderStrong: Color(0x33FFFFFF), // white @ 20%
    textPrimary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    onBrand: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
  );

  /// Clean, premium light experience (not a mere inversion of dark).
  static const DsColors light = DsColors(
    brand: Color(0xFF1680F7),
    brandStrong: Color(0xFF0F6FE0),
    income: Color(0xFF059669),
    expense: Color(0xFFDC2626),
    saving: Color(0xFF2563EB),
    net: Color(0xFF0891B2),
    warning: Color(0xFFD97706),
    bgPage: Color(0xFFF4F7FB),
    bgElevated: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF2F8),
    border: Color(0x14000000), // black @ ~8%
    borderStrong: Color(0x24000000),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF475569),
    textFaint: Color(0xFF94A3B8),
    onBrand: Color(0xFFFFFFFF),
    shadow: Color(0x1A0F172A),
  );

  @override
  DsColors copyWith({
    Color? brand,
    Color? brandStrong,
    Color? income,
    Color? expense,
    Color? saving,
    Color? net,
    Color? warning,
    Color? bgPage,
    Color? bgElevated,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textMuted,
    Color? textFaint,
    Color? onBrand,
    Color? shadow,
  }) {
    return DsColors(
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      saving: saving ?? this.saving,
      net: net ?? this.net,
      warning: warning ?? this.warning,
      bgPage: bgPage ?? this.bgPage,
      bgElevated: bgElevated ?? this.bgElevated,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      onBrand: onBrand ?? this.onBrand,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  DsColors lerp(covariant DsColors? other, double t) {
    if (other == null) return this;
    return DsColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      saving: Color.lerp(saving, other.saving, t)!,
      net: Color.lerp(net, other.net, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Ergonomic accessor: `context.dsColors`.
extension DsColorsX on BuildContext {
  DsColors get dsColors => Theme.of(this).extension<DsColors>()!;
}
