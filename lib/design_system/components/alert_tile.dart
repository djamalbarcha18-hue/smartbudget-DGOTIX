import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// A reusable alert row: colored severity accent + icon, title, description and
/// an optional action. Generic — the caller maps its domain severity to a
/// [color] and [icon], so this widget carries no business logic.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: DsRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: t.titleSmall?.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(description,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                if (actionLabel != null && onAction != null) ...<Widget>[
                  const SizedBox(height: DsSpacing.xs),
                  InkWell(
                    onTap: onAction,
                    borderRadius: DsRadius.brSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(actionLabel!,
                              style: t.labelMedium?.copyWith(color: color)),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
