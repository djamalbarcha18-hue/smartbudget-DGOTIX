import 'package:flutter/material.dart';

/// DGOTIX Design System — semantic color tokens.
///
/// Exposed as a [ThemeExtension] so every widget reads colors from the active
/// theme (`Theme.of(context).extension<DsColors>()!`) instead of hardcoding hex
/// values. This keeps the palette swappable from a single place and makes the
/// system reusable across future DGOTIX products.
///
/// Semantic mapping (premium FinTech glass direction):
///   primary accent   -> teal     (brand)
///   income / growth  -> emerald
///   expense / down   -> rose red (only for losses and warnings)
///   saving / net     -> sky blue / cyan
/// The DGOTIX logo keeps its own blue; UI accents use the tokens below.
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

  /// Premium dark experience (primary theme): deep navy glass with a teal
  /// primary accent, emerald for gains and a rose red reserved for losses and
  /// warnings. Saturation is kept controlled so financial figures stay the
  /// most prominent thing on screen.
  static const DsColors dark = DsColors(
    brand: Color(0xFF2DD4BF), // teal-400 — primary accent
    brandStrong: Color(0xFF5EEAD4),
    income: Color(0xFF34D399), // emerald-400
    expense: Color(0xFFF7566E), // rose red
    saving: Color(0xFF38BDF8), // sky-400
    net: Color(0xFF22D3EE), // cyan-400
    warning: Color(0xFFFBBF24),
    bgPage: Color(0xFF050E1A),
    bgElevated: Color(0xFF0A1828), // opaque sheets, menus, dialogs
    surface: Color(0xFF0F2133),
    surfaceMuted: Color(0x14FFFFFF), // white @ 8% — inset fields on glass
    border: Color(0x1FFFFFFF), // white @ 12%
    borderStrong: Color(0x38FFFFFF), // white @ 22%
    textPrimary: Color(0xFFEAF2F8),
    textMuted: Color(0xFFA3B5C7),
    textFaint: Color(0xFF6F869C),
    onBrand: Color(0xFF042F2B), // dark ink on the bright teal (AA contrast)
    shadow: Color(0x80000000),
  );

  /// Clean, premium light experience (not a mere inversion of dark): frosted
  /// white glass over a cool mist background, same teal/emerald semantics.
  static const DsColors light = DsColors(
    brand: Color(0xFF0D9488), // teal-600
    brandStrong: Color(0xFF0F766E),
    income: Color(0xFF059669),
    expense: Color(0xFFE11D48),
    saving: Color(0xFF0284C7),
    net: Color(0xFF0891B2),
    warning: Color(0xFFD97706),
    bgPage: Color(0xFFEEF4F7),
    bgElevated: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0x0F0F2A3D), // ink @ 6% — inset fields on glass
    border: Color(0x170F2A3D),
    borderStrong: Color(0x290F2A3D),
    textPrimary: Color(0xFF0B1B2B),
    textMuted: Color(0xFF475A6D),
    textFaint: Color(0xFF7A8C9E),
    onBrand: Color(0xFFFFFFFF),
    shadow: Color(0x1A0F2A3D),
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
