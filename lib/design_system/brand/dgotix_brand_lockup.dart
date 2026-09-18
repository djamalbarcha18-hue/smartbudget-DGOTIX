import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/brand/brand_assets.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// DGOTIX + SmartBudget brand lockup.
///
/// Renders the official DGOTIX SVG (auto-swapped for the active theme) as the
/// lead element with the product name ("SmartBudget") set beneath it, smaller —
/// expressing "SmartBudget is a product BY DGOTIX". Ordering is driven by
/// [AppConfig.parentBrandFirst] so the relationship can be flipped in one place.
class DgotixBrandLockup extends StatelessWidget {
  const DgotixBrandLockup({
    super.key,
    this.logoHeight = 40,
    this.showTagline = false,
  });

  /// Rendered height of the DGOTIX SVG.
  final double logoHeight;

  /// Whether to show the product tagline under the product name.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    final Widget logo = SvgPicture.asset(
      BrandAssets.dgotixFor(brightness),
      height: logoHeight,
      semanticsLabel: AppConfig.parentBrand,
      fit: BoxFit.contain,
    );

    final Widget product = Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Smart',
            style: t.titleMedium?.copyWith(color: c.textPrimary),
          ),
          TextSpan(
            text: 'Budget',
            style: t.titleMedium?.copyWith(color: c.brand),
          ),
        ],
      ),
    );

    final List<Widget> children = <Widget>[
      logo,
      const SizedBox(height: DsSpacing.xs),
      product,
      if (showTagline) ...<Widget>[
        const SizedBox(height: DsSpacing.xxs),
        Text(AppConfig.tagline, style: t.labelSmall?.copyWith(color: c.textFaint)),
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: AppConfig.parentBrandFirst
          ? children
          : children.reversed.toList(growable: false),
    );
  }
}
