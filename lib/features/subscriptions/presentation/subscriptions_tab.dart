import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The subscriptions tab: each subscription with its amount, cycle, next
/// charge and card, soonest charge first.
class SubscriptionsTab extends ConsumerWidget {
  const SubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    if (ref.watch(subscriptionsProvider).isLoading) {
      return const Padding(
        padding: EdgeInsets.all(DsSpacing.pageGutter),
        child: DsSkeletonList(count: 4, gap: DsSpacing.sm, framed: true),
      );
    }
    final List<SubscriptionItem> items = ref.watch(subscriptionItemsProvider);
    return ListView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      children: <Widget>[
        Text(l.subIntro, style: t.bodyMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsButton(
            label: l.subAdd,
            icon: Icons.add_rounded,
            onPressed: () => SubscriptionEditorSheet.show(context),
          ),
        ),
        const SizedBox(height: DsSpacing.lg),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xl),
            child: DsEmpty(
              title: l.featSubscriptions,
              message: l.subEmpty,
              icon: Icons.notifications_active_outlined,
            ),
          )
        else
          for (final SubscriptionItem i in items) ...<Widget>[
            SubscriptionCard(item: i),
            const SizedBox(height: DsSpacing.md),
          ],
      ],
    );
  }
}

/// One subscription: name, amount and cycle, next charge, card name.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key, required this.item});
  final SubscriptionItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    final Locale locale = Localizations.localeOf(context);
    final Subscription s = item.sub;
    final RecurringRule? r = item.rule;
    final DateTime? next =
        r == null ? null : SubscriptionSchedule.nextCharge(r, AppClock.now());
    final String initial =
        s.provider.trim().isEmpty ? '?' : s.provider.trim().characters.first;
    final Color tone = _toneOf(s.provider, c);

    return GlassCard(
      onTap: () => SubscriptionEditorSheet.show(context, existing: item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: tone.withValues(alpha: 0.18),
            child: Text(initial.toUpperCase(),
                style: t.titleMedium?.copyWith(color: tone)),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.provider,
                    style: t.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (r != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    '${MoneyFormatter.format(r.amount)} · ${repeatLabel(l, r.frequency)}',
                    style: t.bodyMedium,
                  ),
                ],
                if (next != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    s.isTrial
                        ? '${l.subTrialEnds}: ${dayText(locale, next)}'
                        : l.subNextOn(dayText(locale, next)),
                    style: t.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ],
                const SizedBox(height: DsSpacing.xs),
                Wrap(
                  spacing: DsSpacing.xs,
                  runSpacing: DsSpacing.xs,
                  children: <Widget>[
                    if (s.cardName != null)
                      _CardChip(name: s.cardName!),
                    if (s.isTrial)
                      DsBadge(label: l.subTrial, tone: DsBadgeTone.warning),
                    if (!s.remindersOn)
                      DsBadge(label: l.subRemindersOff),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A steady colour per name (not a brand colour: no logos).
  static Color _toneOf(String name, DsColors c) {
    final List<Color> tones = <Color>[
      c.brand,
      c.saving,
      c.income,
      c.warning,
      c.net,
    ];
    int h = 0;
    for (final int u in name.toLowerCase().codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return tones[h % tones.length];
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.credit_card_rounded, size: 14, color: c.textMuted),
          const SizedBox(width: 4),
          Text(name,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}
