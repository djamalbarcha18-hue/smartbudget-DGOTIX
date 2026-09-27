import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/daret/presentation/daret_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

String _ymd(DateTime d) =>
    '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069';

class DaretPage extends ConsumerWidget {
  const DaretPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<Daret> darets =
        ref.watch(daretsProvider).valueOrNull ?? const <Daret>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.navDaret, style: t.headlineSmall),
                  const SizedBox(height: DsSpacing.xs),
                  Text(l.daretSubtitle,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
              DsButton(
                label: l.daretNew,
                icon: Icons.add_rounded,
                onPressed: () => DaretEditorSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xl),
          if (darets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.x5l),
              child: DsEmpty(
                title: l.daretEmptyTitle,
                message: l.daretEmptyBody,
                icon: Icons.groups_2_outlined,
              ),
            )
          else
            for (final Daret d in darets) ...<Widget>[
              _DaretCard(daret: d),
              const SizedBox(height: DsSpacing.lg),
            ],
        ],
      ),
    );
  }
}

class _DaretCard extends ConsumerWidget {
  const _DaretCard({required this.daret});
  final Daret daret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Daret d = daret;
    final DateTime now = AppClock.now();
    final DaretActions actions = ref.read(daretActionsProvider);

    final int due = DaretMath.roundsDue(d, now);
    final bool finished = DaretMath.finished(d, now);
    final List<int> overdue = DaretMath.overdue(d, now);
    final int? nextPay = DaretMath.nextUnpaid(d);
    final DateTime myTurn = DaretMath.myTurn(d);
    final bool turnReached = !myTurn.isAfter(DateTime(now.year, now.month, now.day));

    final String status = finished
        ? l.daretFinished
        : due == 0
            ? l.daretNotStarted
            : l.daretRoundOf(due, d.rounds);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.14),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(Icons.groups_2_outlined, color: c.brand),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(d.name,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${d.frequency == DaretFrequency.monthly ? l.daretMonthly : l.daretWeekly} · ${l.daretMembersCount(d.rounds)} · $status',
                      style: t.bodySmall?.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await DaretEditorSheet.show(context, existing: d);
                  } else if (v == 'delete') {
                    await actions.delete(d.id);
                  }
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(
                      value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          Wrap(
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              _Stat(
                  label: l.daretContribution,
                  value: MoneyFormatter.format(d.contribution)),
              _Stat(
                  label: l.daretPot,
                  value: MoneyFormatter.format(d.pot),
                  color: c.income),
              _Stat(
                  label: l.daretMyTurn,
                  value: '#${d.meIndex + 1} · ${_ymd(myTurn)}',
                  color: c.brand),
              _Stat(
                  label: l.daretPaid,
                  value:
                      '${MoneyFormatter.format(DaretMath.paid(d))} / ${MoneyFormatter.format(d.pot)}'),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),

          // Round timeline: who collects when; tap a round to mark your
          // contribution for it as paid.
          Text(l.daretTimeline,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DsSpacing.xs),
          Text(l.daretTimelineHint,
              style: t.labelSmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.sm),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: d.rounds,
              separatorBuilder: (_, __) => const SizedBox(width: DsSpacing.sm),
              itemBuilder: (BuildContext context, int i) {
                final bool paid = d.paidRounds.contains(i);
                final bool late = overdue.contains(i);
                final bool mine = i == d.meIndex;
                final bool current = !finished && i == due - 1;
                final Color edge = late
                    ? c.expense
                    : mine
                        ? c.brand
                        : current
                            ? c.income
                            : c.border;
                return InkWell(
                  borderRadius: DsRadius.brMd,
                  onTap: () => actions.togglePaid(d, i),
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(DsSpacing.sm),
                    decoration: BoxDecoration(
                      color: mine
                          ? c.brand.withValues(alpha: 0.10)
                          : c.surfaceMuted,
                      borderRadius: DsRadius.brMd,
                      border: Border.all(color: edge, width: current || mine ? 1.6 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text('#${i + 1}',
                                style: t.labelSmall?.copyWith(
                                    color: c.textMuted,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Icon(
                              paid
                                  ? Icons.check_circle_rounded
                                  : late
                                      ? Icons.error_outline_rounded
                                      : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: paid
                                  ? c.income
                                  : late
                                      ? c.expense
                                      : c.textFaint,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                d.members[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: mine ? c.brand : null),
                              ),
                            ),
                            if (mine) ...<Widget>[
                              const SizedBox(width: 4),
                              Icon(Icons.star_rounded,
                                  size: 14, color: c.brand),
                            ],
                          ],
                        ),
                        Text(_ymd(DaretMath.roundDate(d, i)),
                            style: t.labelSmall
                                ?.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (overdue.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, size: 16, color: c.expense),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(l.daretOverdue(overdue.length),
                      style: t.bodySmall?.copyWith(color: c.expense)),
                ),
              ],
            ),
          ],
          const SizedBox(height: DsSpacing.lg),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              if (nextPay != null)
                DsButton(
                  label: l.daretMarkPaid(nextPay + 1),
                  icon: Icons.check_rounded,
                  onPressed: () => actions.togglePaid(d, nextPay),
                ),
              if (turnReached)
                DsButton(
                  label: d.payoutReceived
                      ? l.daretReceivedDone
                      : l.daretMarkReceived(MoneyFormatter.format(d.pot)),
                  icon: d.payoutReceived
                      ? Icons.verified_rounded
                      : Icons.payments_outlined,
                  variant: DsButtonVariant.secondary,
                  onPressed: () => actions.setReceived(d, !d.payoutReceived),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                  child: Text(
                    l.daretTurnIn(myTurn.difference(DateTime(now.year, now.month, now.day)).inDays),
                    style: t.bodySmall?.copyWith(color: c.brand),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: t.labelSmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: t.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
