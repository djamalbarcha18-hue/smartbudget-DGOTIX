import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A thin rounded progress bar (value 0..1).
class TripBar extends StatelessWidget {
  const TripBar({super.key, required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: context.dsColors.surfaceMuted,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
}

/// A small label over a figure.
class TripStat extends StatelessWidget {
  const TripStat(
      {super.key, required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: t.labelSmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.xxs),
        Text(value,
            style: t.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

/// A rounded tinted label ("Planning", "Ongoing", "in 12 days").
class TripChip extends StatelessWidget {
  const TripChip({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

/// "Food is 40 over its share; Activities still has 60 to cover it."
class TripTipBox extends StatelessWidget {
  const TripTipBox({super.key, required this.tip});
  final TripItemTip tip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    String money(Money m) => MoneyFormatter.format(m);
    return Container(
      padding: const EdgeInsets.all(DsSpacing.sm),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.1),
        borderRadius: DsRadius.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: c.warning),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(
              tip.spare == null
                  ? l.tripTipOver(tripItemLabel(l, tip.over), money(tip.overBy))
                  : l.tripTipCover(
                      tripItemLabel(l, tip.over),
                      money(tip.overBy),
                      tripItemLabel(l, tip.spare!),
                      money(tip.spareLeft!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
