import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Direction of a period-over-period change on a KPI.
enum KpiTrend { up, down, flat }

/// A month-over-month delta shown on a KPI card.
class KpiDelta {
  const KpiDelta({required this.label, required this.trend});
  final String label; // e.g. "+12.5%"
  final KpiTrend trend;
}

/// Premium KPI tile: label + big value + optional trend + optional sparkline.
///
/// [value] is nullable ON PURPOSE: with no real SmartBudget data wired yet, the
/// card renders a neutral empty state ("—") rather than a fabricated number.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconChild,
    this.delta,
    this.accent,
    this.caption,
    this.sparkline,
  });

  final String label;
  final String? value;
  final IconData? icon;

  /// A custom glyph (e.g. SavingsJarGlyph) rendered inside the icon chip in
  /// place of a Material [icon]. Its colour/size come from the chip's IconTheme.
  final Widget? iconChild;
  final KpiDelta? delta;
  final Color? accent;
  final String? caption;

  /// Optional chart widget rendered under the value (wired in later phases).
  final Widget? sparkline;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Color accentColor = accent ?? c.brand;

    return GlassCard(
      accent: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null || iconChild != null) ...<Widget>[
                _IconChip(icon: icon, iconChild: iconChild, color: accentColor),
                const SizedBox(width: DsSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: t.titleSmall?.copyWith(color: c.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (delta != null) _TrendPill(delta: delta!),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            value ?? '—',
            style: DsTypography.mono(
              t.headlineMedium ?? const TextStyle(),
            ).copyWith(color: value == null ? c.textFaint : c.textPrimary),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: DsSpacing.xxs),
            Text(caption!, style: t.labelSmall?.copyWith(color: c.textFaint)),
          ],
          if (sparkline != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            SizedBox(height: 40, child: sparkline),
          ],
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({this.icon, this.iconChild, required this.color});
  final IconData? icon;
  final Widget? iconChild;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: iconChild != null
          ? IconTheme.merge(
              data: IconThemeData(color: color, size: 18),
              child: iconChild!,
            )
          : Icon(icon, size: 18, color: color),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta});
  final KpiDelta delta;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color color = switch (delta.trend) {
      KpiTrend.up => c.income,
      KpiTrend.down => c.expense,
      KpiTrend.flat => c.textMuted,
    };
    final IconData icon = switch (delta.trend) {
      KpiTrend.up => Icons.trending_up_rounded,
      KpiTrend.down => Icons.trending_down_rounded,
      KpiTrend.flat => Icons.trending_flat_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            delta.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
