import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A date as digits that keep their order in a right-to-left line.
String daretYmd(DateTime d) =>
    '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069';

/// The schedule of a daret as one card: who collects in which round, and when.
/// Shown in the share sheet (and captured as the picture to send) and in the
/// import sheet, where a tap on a row says "this one is me".
class DaretScheduleCard extends StatelessWidget {
  const DaretScheduleCard({
    super.key,
    required this.name,
    required this.contribution,
    required this.frequency,
    required this.start,
    required this.members,
    this.selected,
    this.onSelect,
    this.footer,
  });

  final String name;
  final Money contribution;
  final DaretFrequency frequency;
  final DateTime start;
  final List<String> members;

  /// The highlighted row, if any.
  final int? selected;

  /// Makes the rows tappable (the import sheet).
  final ValueChanged<int>? onSelect;

  /// A line under the rows (the brand, on the picture).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    // Dates come from the same rule the app uses everywhere else.
    final Daret d = Daret(
      id: '',
      name: name,
      contribution: contribution,
      frequency: frequency,
      start: start,
      members: members,
      meIndex: 0,
      createdAt: start,
    );
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: DsRadius.brLg,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.groups_2_outlined, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(name,
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${MoneyFormatter.format(contribution)} · '
            '${frequency == DaretFrequency.monthly ? l.daretMonthly : l.daretWeekly} · '
            '${l.daretMembersCount(members.length)} · '
            '${l.daretPot}: ${MoneyFormatter.format(d.pot)}',
            style: t.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: DsSpacing.sm),
          for (int i = 0; i < members.length; i++)
            _Row(
              index: i,
              member: members[i],
              date: DaretMath.roundDate(d, i),
              selected: selected == i,
              onTap: onSelect == null ? null : () => onSelect!(i),
              roundLabel: l.daretScheduleRound,
            ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: DsSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.index,
    required this.member,
    required this.date,
    required this.selected,
    required this.onTap,
    required this.roundLabel,
  });

  final int index;
  final String member;
  final DateTime date;
  final bool selected;
  final VoidCallback? onTap;
  final String roundLabel;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Widget row = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.sm, vertical: DsSpacing.xs + 2),
      decoration: BoxDecoration(
        color: selected ? c.brand.withValues(alpha: 0.12) : c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(
            color: selected ? c.brand : c.border, width: selected ? 1.6 : 1),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.brand : c.bgElevated,
              border: Border.all(color: selected ? c.brand : c.border),
            ),
            child: Text('${index + 1}',
                style: t.labelSmall?.copyWith(
                    color: selected ? Colors.white : c.textMuted,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            // A name from a link is someone else's text: isolated, one line.
            child: Text('\u2068$member\u2069',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(daretYmd(date),
              style: t.labelMedium?.copyWith(color: c.textMuted)),
          if (selected) ...<Widget>[
            const SizedBox(width: DsSpacing.xs),
            Icon(Icons.check_circle_rounded, size: 18, color: c.brand),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      selected: selected,
      label: '$roundLabel ${index + 1}, $member',
      child: InkWell(
          key: ValueKey<String>('daret-member-$index'),
          borderRadius: DsRadius.brMd,
          onTap: onTap,
          child: ExcludeSemantics(child: row)),
    );
  }
}
