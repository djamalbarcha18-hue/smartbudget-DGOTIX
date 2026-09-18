import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// Semantic badge tone.
enum DsBadgeTone { brand, income, expense, saving, warning, neutral }

/// Small status/label pill (e.g. "جديد" / "Pro" / status chips).
class DsBadge extends StatelessWidget {
  const DsBadge({super.key, required this.label, this.tone = DsBadgeTone.neutral});

  final String label;
  final DsBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color color = switch (tone) {
      DsBadgeTone.brand => c.brand,
      DsBadgeTone.income => c.income,
      DsBadgeTone.expense => c.expense,
      DsBadgeTone.saving => c.saving,
      DsBadgeTone.warning => c.warning,
      DsBadgeTone.neutral => c.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
