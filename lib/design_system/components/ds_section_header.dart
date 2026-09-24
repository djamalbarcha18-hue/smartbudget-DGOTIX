import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// Section title row with an optional trailing action (e.g. "View all").
class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.brand.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 16, color: c.brand),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
