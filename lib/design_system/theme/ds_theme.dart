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
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: DsRadius.brSm,
          border: Border.all(color: colors.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, glass],
    );
  }
}
