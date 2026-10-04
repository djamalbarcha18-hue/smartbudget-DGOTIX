import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/brand/brand_assets.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// How a lockup badge stands out (light mode; dark mode is always gray).
enum LockupBadgeStyle {
  /// Gray outline.
  subtle,

  /// Blue outline.
  accent,

  /// Solid blue.
  solid,
}

/// The DGOTIX master lockup: the official DGOTIX logo, then the
/// "Digital Productivity Solutions" line, then "SmartBudget" with an optional
/// badge (the plan, e.g. "PRO"), as in the brand master (DGOTIX_MASTER).
///
/// Dark mode shows it all in the logo's gray; light mode in color (blue mark,
/// "Smart" dark, "Budget" blue, a colored badge). The two lines under the
/// logo are text rather than part of the SVG: at the master's proportions
/// they would be about 3 px tall at in-app sizes.
class DgotixBrandLockup extends StatelessWidget {
  const DgotixBrandLockup({
    super.key,
    this.logoHeight = 40,
    this.badge,
    this.badgeStyle = LockupBadgeStyle.solid,
  });

  /// Rendered height of the DGOTIX logo; the lines beneath scale with it.
  final double logoHeight;

  /// Short label after "SmartBudget" (e.g. "PRO"); none when null.
  final String? badge;

  final LockupBadgeStyle badgeStyle;

  /// The logo's own gray (dgotix-logo-mono.svg), for dark mode.
  static const Color _mono = Color(0xFFA6ABB3);

  /// The master's lighter gray for the lines beneath the logo.
  static const Color _monoText = Color(0xFFB8BEC8);

  /// Width of the official logo for a given height (its viewBox is 708×189).
  static double logoWidthFor(double height) => height * 708 / 189;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final DsColors c = context.dsColors;
    final double width = logoWidthFor(logoHeight);
    // Readable at the smallest lockup, growing with larger ones.
    final double taglineSize = (logoHeight * 0.17).clamp(9.0, 14.0);
    final double productSize = (logoHeight * 0.24).clamp(12.0, 20.0);

    final TextStyle tagline = GoogleFonts.inter(
      fontSize: taglineSize,
      fontWeight: FontWeight.w400,
      letterSpacing: taglineSize * 0.16,
      color: dark ? _monoText.withValues(alpha: 0.85) : c.textMuted,
    );
    final TextStyle product = GoogleFonts.inter(
      fontSize: productSize,
      fontWeight: FontWeight.w500,
      letterSpacing: productSize * 0.12,
      height: 1.1,
    );

    final Widget productLine = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text.rich(
          TextSpan(children: <TextSpan>[
            TextSpan(
              text: 'Smart',
              style: product.copyWith(color: dark ? _monoText : c.textPrimary),
            ),
            TextSpan(
              text: 'Budget',
              style: product.copyWith(color: dark ? _monoText : c.brand),
            ),
          ]),
        ),
        if (badge != null) ...<Widget>[
          SizedBox(width: productSize * 0.4),
          _Badge(
            label: badge!,
            style: badgeStyle,
            size: productSize * 0.62,
            dark: dark,
            colors: c,
          ),
        ],
      ],
    );

    return Semantics(
      label: '${AppConfig.parentBrand} · Digital Productivity Solutions · '
          '${AppConfig.appName}${badge == null ? '' : ' $badge'}',
      container: true,
      child: ExcludeSemantics(
        // The brand reads left to right in every language ("SmartBudget PRO").
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  BrandAssets.dgotixFor(brightness),
                  height: logoHeight,
                  width: width,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: logoHeight * 0.1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Digital Productivity Solutions',
                      maxLines: 1, style: tagline),
                ),
                SizedBox(height: logoHeight * 0.06),
                FittedBox(fit: BoxFit.scaleDown, child: productLine),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The rounded badge after the product name.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.style,
    required this.size,
    required this.dark,
    required this.colors,
  });

  final String label;
  final LockupBadgeStyle style;
  final double size;
  final bool dark;
  final DsColors colors;

  @override
  Widget build(BuildContext context) {
    const Color mono = DgotixBrandLockup._mono;
    final Color brand = colors.brand;
    final (Color fill, Color border, Color text) = dark
        ? (mono.withValues(alpha: 0.18), mono.withValues(alpha: 0.7),
            DgotixBrandLockup._monoText)
        : switch (style) {
            LockupBadgeStyle.subtle =>
              (Colors.transparent, colors.textFaint, colors.textMuted),
            LockupBadgeStyle.accent =>
              (brand.withValues(alpha: 0.10), brand, brand),
            LockupBadgeStyle.solid => (brand, brand, Colors.white),
          };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.7, vertical: size * 0.18),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w600,
          letterSpacing: size * 0.14,
          height: 1.1,
          color: text,
        ),
      ),
    );
  }
}
