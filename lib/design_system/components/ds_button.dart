import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';

enum DsButtonVariant { primary, secondary, ghost }

/// Standardized DS button (consistent height, radius, brand fill).
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DsButtonVariant.primary,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DsButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;

    final ButtonStyle style = switch (variant) {
      DsButtonVariant.primary => FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
        ),
      DsButtonVariant.secondary => FilledButton.styleFrom(
          backgroundColor: c.surfaceMuted,
          foregroundColor: c.textPrimary,
        ),
      DsButtonVariant.ghost => FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
        ),
    }
        .copyWith(
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: DsRadius.brMd),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        Theme.of(context).textTheme.labelLarge,
      ),
    );

    final Widget button = FilledButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
