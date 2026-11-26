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
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/subscriptions/data/subscription_notifications.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_cancel.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_due.dart';
import 'package:smartbudget/features/subscriptions/presentation/subscription_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_summary.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// How the list is ordered or grouped.
enum SubscriptionOrder { date, kind, card, name }

/// The subscriptions tab: what they cost, the charges to confirm, then each
/// subscription (soonest charge first by default), the ended ones last.
class SubscriptionsTab extends ConsumerStatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  ConsumerState<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends ConsumerState<SubscriptionsTab> {
  SubscriptionOrder _order = SubscriptionOrder.date;

  @override
  Widget build(BuildContext context) {
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
    final List<DueCharge> due = ref.watch(subscriptionDueProvider);
    final List<SubscriptionItem> running = <SubscriptionItem>[
      for (final SubscriptionItem i in items)
        if (!i.sub.isOver) i,
    ];
    final List<SubscriptionItem> over = <SubscriptionItem>[
      for (final SubscriptionItem i in items)
        if (i.sub.isOver) i,
    ];
    final SubscriptionSummary? summary = items.isEmpty
        ? null
        : SubscriptionSummary.of(items, AppClock.now(),
            base: ref.watch(baseCurrencyProvider),
            ratesVsUsd: ref.watch(ratesProvider));
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
        if (items.any((SubscriptionItem i) => i.sub.remindersOn)) ...<Widget>[
          const SizedBox(height: DsSpacing.md),
          const _ReminderReach(),
        ],
        const SizedBox(height: DsSpacing.lg),
        if (summary != null) ...<Widget>[
          SubscriptionSummaryCard(summary: summary),
          const SizedBox(height: DsSpacing.lg),
        ],
        // "Was it charged?" first: an answer is waited for.
        for (final DueCharge d in due) ...<Widget>[
          SubscriptionDueCard(
              key: ValueKey<String>('${d.item.sub.id}-${d.date}'), due: d),
          const SizedBox(height: DsSpacing.md),
        ],
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xl),
            child: DsEmpty(
              title: l.featSubscriptions,
              message: l.subEmpty,
              icon: Icons.notifications_active_outlined,
            ),
          )
        else ...<Widget>[
          if (running.length > 1) ...<Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final SubscriptionOrder o in SubscriptionOrder.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          end: DsSpacing.xs),
                      child: ChoiceChip(
                        label: Text(_orderLabel(l, o)),
                        selected: _order == o,
                        onSelected: (_) => setState(() => _order = o),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
          ],
          ..._list(l, t, c, summary, running),
          if (over.isNotEmpty)
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('${l.subEndedTitle} (${over.length})',
                    style: t.titleSmall?.copyWith(color: c.textMuted)),
                children: <Widget>[
                  for (final SubscriptionItem i in over) ...<Widget>[
                    SubscriptionCard(item: i),
                    const SizedBox(height: DsSpacing.md),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  static String _orderLabel(AppLocalizations l, SubscriptionOrder o) =>
      switch (o) {
        SubscriptionOrder.date => l.subSortDate,
        SubscriptionOrder.kind => l.subSortKind,
        SubscriptionOrder.card => l.subSortCard,
        SubscriptionOrder.name => l.subSortName,
      };

  /// The running subscriptions in the chosen order, with a header per group
  /// (type, or card with its monthly cost).
  List<Widget> _list(AppLocalizations l, TextTheme t, DsColors c,
      SubscriptionSummary? summary, List<SubscriptionItem> running) {
    List<Widget> cards(Iterable<SubscriptionItem> xs) => <Widget>[
          for (final SubscriptionItem i in xs) ...<Widget>[
            SubscriptionCard(item: i),
            const SizedBox(height: DsSpacing.md),
          ],
        ];
    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(bottom: DsSpacing.sm),
          child: Text(text, style: t.titleSmall?.copyWith(color: c.textMuted)),
        );
    switch (_order) {
      case SubscriptionOrder.date:
        return cards(running);
      case SubscriptionOrder.name:
        return cards(running.toList()
          ..sort((SubscriptionItem a, SubscriptionItem b) => a.sub.provider
              .toLowerCase()
              .compareTo(b.sub.provider.toLowerCase())));
      case SubscriptionOrder.kind:
        return <Widget>[
          for (final SubscriptionKind k in SubscriptionKind.values)
            if (running.any((SubscriptionItem i) => i.sub.kind == k)) ...<Widget>[
              header(k == SubscriptionKind.digital
                  ? l.subKindDigital
                  : l.subKindMobile),
              ...cards(running.where((SubscriptionItem i) => i.sub.kind == k)),
            ],
        ];
      case SubscriptionOrder.card:
        final List<({String? card, int monthly, int count})> groups =
            summary?.byCard ?? const <({String? card, int monthly, int count})>[];
        final Set<String?> shown = <String?>{};
        return <Widget>[
          for (final ({String? card, int monthly, int count}) g in groups)
            if (shown.add(g.card)) ...<Widget>[
              header('${g.card ?? l.subNoCard} · '
                  '${MoneyFormatter.format(Money(g.monthly, summary!.base))} / ${l.subSumMonthly}'),
              ...cards(
                  running.where((SubscriptionItem i) => i.sub.cardName == g.card)),
            ],
          // Those not in the totals (cancelled to the end of the period, no
          // rate): still listed.
          for (final String? card in <String?>{
            for (final SubscriptionItem i in running) i.sub.cardName,
          })
            if (!shown.contains(card)) ...<Widget>[
              header(card ?? l.subNoCard),
              ...cards(
                  running.where((SubscriptionItem i) => i.sub.cardName == card)),
            ],
        ];
    }
  }
}

/// What the subscriptions cost a month and a year, and where they stand.
class SubscriptionSummaryCard extends StatelessWidget {
  const SubscriptionSummaryCard({super.key, required this.summary});
  final SubscriptionSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    final SubscriptionSummary s = summary;
    Widget total(String label, int minor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: t.labelMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(MoneyFormatter.format(Money(minor, s.base)),
                    style: t.titleLarge),
              ),
            ],
          ),
        );
    Widget stat(String label, int n, {Color? tone}) => Expanded(
          child: Column(
            children: <Widget>[
              Text('$n', style: t.titleMedium?.copyWith(color: tone)),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: t.labelSmall?.copyWith(color: c.textMuted)),
            ],
          ),
        );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              total(l.subSumMonthly, s.monthly),
              const SizedBox(width: DsSpacing.md),
              total(l.subSumYearly, s.yearly),
            ],
          ),
          if (s.estimated || s.missingRates.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xs),
            Text(
              <String>[
                if (s.estimated) l.subSumEstimated,
                if (s.missingRates.isNotEmpty)
                  l.subSumMissing(s.missingRates.join(', ')),
              ].join(' '),
              style: t.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
          const SizedBox(height: DsSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              stat(l.subSumActive, s.active),
              stat(l.subSumSoon, s.renewingSoon,
                  tone: s.renewingSoon > 0 ? c.warning : null),
              stat(l.subSumToCancel, s.toCancel,
                  tone: s.toCancel > 0 ? c.expense : null),
              stat(l.subSumEnded, s.ended),
            ],
          ),
        ],
      ),
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
                if (next != null &&
                    !SubscriptionCancel.stopsCharges(s.status)) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    s.trialEndsOn(next)
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
                    if (next != null && s.trialEndsOn(next))
                      DsBadge(label: l.subTrial, tone: DsBadgeTone.warning),
                    if (statusText(l, locale, s) case final String st)
                      DsBadge(label: st, tone: DsBadgeTone.warning),
                    if (!s.remindersOn && !s.isOver)
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

/// Whether the reminders can reach the user: on the web they can't (the
/// list and the dashboard show what is coming); on the phone, notifications
/// may be turned off.
class _ReminderReach extends StatefulWidget {
  const _ReminderReach();

  @override
  State<_ReminderReach> createState() => _ReminderReachState();
}

class _ReminderReachState extends State<_ReminderReach>
    with WidgetsBindingObserver {
  bool _allowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the phone's settings: look again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!SubscriptionNotifications.supported) return;
    try {
      final bool ok = await ReminderNotifications.instance.allowed();
      if (mounted && ok != _allowed) setState(() => _allowed = ok);
    } catch (_) {
      // Unknown: say nothing rather than a wrong warning.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    if (!SubscriptionNotifications.supported) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: c.textMuted),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(l.subWebNote,
                style: t.bodySmall?.copyWith(color: c.textMuted)),
          ),
        ],
      );
    }
    if (_allowed) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.reminderPermissionDenied,
            style: t.bodySmall?.copyWith(color: c.warning)),
        TextButton.icon(
          onPressed: () => ReminderNotifications.instance.openSystemSettings(),
          icon: const Icon(Icons.notifications_active_outlined, size: 18),
          label: Text(l.actionOpenSettings),
        ),
      ],
    );
  }
}
