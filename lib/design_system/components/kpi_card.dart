import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Direction of a period-over-period change on a KPI (drives the arrow only).
enum KpiTrend { up, down, flat }

/// Semantic reading of the change for THIS KPI (drives the color). Income up is
/// good; expenses up is bad — never inferred from the arrow direction.
enum KpiTone { good, bad, neutral }

/// A period-over-period delta shown on a KPI card.
class KpiDelta {
  const KpiDelta({
    required this.label,
    required this.trend,
    this.tone = KpiTone.neutral,
    this.comparable = true,
  });

  /// A delta with no valid baseline — shows [label] (e.g. "No comparison") with
  /// no arrow and a neutral color, never a misleading percentage.
  const KpiDelta.noComparison(this.label)
      : trend = KpiTrend.flat,
        tone = KpiTone.neutral,
        comparable = false;

  final String label; // e.g. "+12.5%"
  final KpiTrend trend;
  final KpiTone tone;
  final bool comparable;
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

  /// The metric's semantic color. Kept for API compatibility; the chrome now
  /// uses the brand blue everywhere (see build).
  final Color? accent;
  final String? caption;

  /// Optional chart widget rendered under the value (wired in later phases).
  final Widget? sparkline;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    // Icons use the logo blue on every card so the row reads as one calm
    // unit; the metric's meaning is carried by the change badge's color.
    final Color accentColor = c.brand;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
          DsSpacing.lg, DsSpacing.lg, DsSpacing.lg, DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null || iconChild != null) ...<Widget>[
                _IconChip(icon: icon, iconChild: iconChild, color: accentColor),
                const SizedBox(width: DsSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: t.titleSmall?.copyWith(
                      color: c.textMuted, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          // The figure is the hero: large, tabular, never clipped (it scales
          // down instead on narrow tiles).
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value ?? '—',
              maxLines: 1,
              style: DsTypography.mono(
                t.headlineMedium ?? const TextStyle(),
              ).copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: value == null ? c.textFaint : c.textPrimary,
              ),
            ),
          ),
          if (delta != null || caption != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            Row(
              children: <Widget>[
                if (delta != null) ...<Widget>[
                  _TrendPill(delta: delta!),
                  const SizedBox(width: DsSpacing.sm),
                ],
                if (caption != null)
                  Flexible(
                    child: Text(caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(color: c.textFaint)),
                  ),
              ],
            ),
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
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14),
        ],
      ),
      child: iconChild != null
          ? IconTheme.merge(
              data: IconThemeData(color: color, size: 20),
              child: iconChild!,
            )
          : Icon(icon, size: 20, color: color),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta});
  final KpiDelta delta;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    // Color is driven by the semantic tone, NOT the arrow direction.
    final Color color = switch (delta.tone) {
      KpiTone.good => c.income,
      KpiTone.bad => c.expense,
      KpiTone.neutral => c.textMuted,
    };
    final IconData? icon = !delta.comparable
        ? null
        : switch (delta.trend) {
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
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
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
