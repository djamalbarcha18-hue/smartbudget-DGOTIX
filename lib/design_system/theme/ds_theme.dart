import 'package:flutter/material.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Assembles [ThemeData] for light & dark from DGOTIX design tokens.
///
/// All colors flow from [DsColors]/[DsGlass] theme extensions, so a token change
/// in one file re-themes the whole app. Widgets should prefer `context.dsColors`
/// over `ColorScheme` where a semantic (income/expense/…) is needed.
abstract final class DsTheme {
  static ThemeData dark({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.dark,
        colors: DsColors.dark,
        glass: DsGlass.dark,
        lang: lang,
      );

  static ThemeData light({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.light,
        colors: DsColors.light,
        glass: DsGlass.light,
        lang: lang,
      );

  /// Beige (Pro): the warm light theme.
  static ThemeData beige({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.light,
        colors: DsColors.beige,
        glass: DsGlass.beige,
        lang: lang,
      );

  /// Black Gold (Pro): graphite black and gold, the dark Pro theme.
  static ThemeData black({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.dark,
        colors: DsColors.black,
        glass: DsGlass.black,
        lang: lang,
      );

  /// Pomegranate (Pro): rose and deep wine.
  static ThemeData pomegranate({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.light,
        colors: DsColors.pomegranate,
        glass: DsGlass.pomegranate,
        lang: lang,
      );

  /// Sage (Pro): the light grey-green theme.
  static ThemeData sage({AppLang lang = AppLang.en}) => _build(
        brightness: Brightness.light,
        colors: DsColors.sage,
        glass: DsGlass.sage,
        lang: lang,
      );

  static ThemeData _build({
    required Brightness brightness,
    required DsColors colors,
    required DsGlass glass,
    required AppLang lang,
  }) {
    final TextTheme textTheme = DsTypography.textTheme(
      primary: colors.textPrimary,
      muted: colors.textMuted,
      lang: lang,
    );

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      secondary: colors.saving,
      onSecondary: colors.onBrand,
      error: colors.expense,
      onError: colors.onBrand,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bgPage,
      canvasColor: colors.bgPage,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      // Icons default to the logo blue across the whole app.
      iconTheme: IconThemeData(color: colors.brand, size: 20),
      // The chosen segment in the theme's accent (not the savings colour).
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? colors.brand : null),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? colors.onBrand
                  : colors.textPrimary),
          side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: colors.borderStrong)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: DsRadius.brSm,
          border: Border.all(color: colors.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      ),
      datePickerTheme: _datePicker(colors, textTheme),
      extensions: <ThemeExtension<dynamic>>[colors, glass],
    );
  }

  /// The date picker in the theme's colours: a header in the accent, the
  /// chosen day filled with it, today ringed, the typed-date field like the
  /// app's own fields.
  static DatePickerThemeData _datePicker(DsColors c, TextTheme t) {
    Color? on(Set<WidgetState> s, Color selected, Color? rest) =>
        s.contains(WidgetState.disabled)
            ? c.textFaint
            : s.contains(WidgetState.selected)
                ? selected
                : rest;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: color, width: width),
        );
    return DatePickerThemeData(
      backgroundColor: c.bgElevated,
      surfaceTintColor: Colors.transparent,
      shadowColor: c.shadow,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: DsRadius.brXl,
        side: BorderSide(color: c.border),
      ),
      headerBackgroundColor: c.brand,
      headerForegroundColor: c.onBrand,
      headerHeadlineStyle:
          t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      headerHelpStyle: t.labelLarge,
      subHeaderForegroundColor: c.textPrimary,
      weekdayStyle: t.labelMedium
          ?.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
      dayStyle: t.bodyMedium,
      dayForegroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => on(s, c.onBrand, c.textPrimary)),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? c.brand : null),
      dayOverlayColor:
          WidgetStatePropertyAll<Color>(c.brand.withValues(alpha: 0.12)),
      todayForegroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => on(s, c.onBrand, c.brand)),
      todayBackgroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? c.brand : null),
      todayBorder: BorderSide(color: c.brand, width: 1.5),
      yearStyle: t.bodyLarge,
      yearForegroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => on(s, c.onBrand, c.textPrimary)),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? c.brand : null),
      yearOverlayColor:
          WidgetStatePropertyAll<Color>(c.brand.withValues(alpha: 0.12)),
      dividerColor: c.border,
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.textMuted),
      confirmButtonStyle: TextButton.styleFrom(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.brand, 1.5),
        errorBorder: border(c.expense),
        focusedErrorBorder: border(c.expense, 1.5),
      ),
    );
  }
}
