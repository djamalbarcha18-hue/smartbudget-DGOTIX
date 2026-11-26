import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/application/subscriptions_controller.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_payments.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Was it charged?" for one charge date: yes (recorded as an expense),
/// "I recorded it myself" (linked, nothing new written), or not charged.
class SubscriptionDueCard extends ConsumerStatefulWidget {
  const SubscriptionDueCard({super.key, required this.due});
  final DueCharge due;

  @override
  ConsumerState<SubscriptionDueCard> createState() =>
      _SubscriptionDueCardState();
}

class _SubscriptionDueCardState extends ConsumerState<SubscriptionDueCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _yes() async {
    final RecurringRule rule = widget.due.item.rule!;
    final ({Money amount, bool forFuture})? r =
        await showDialog<({Money amount, bool forFuture})>(
      context: context,
      builder: (BuildContext ctx) => _AmountDialog(amount: rule.amount),
    );
    if (r == null) return;
    await _run(() => ref.read(subscriptionActionsProvider).confirmCharge(
        widget.due.item, widget.due.date, r.amount,
        forFuture: r.forFuture));
  }

  Future<void> _mine() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final List<Transaction> all =
        await ref.read(transactionsProvider.future);
    if (!mounted) return;
    final List<Transaction> found = SubscriptionPayments.candidates(
      widget.due.item.rule!,
      widget.due.date,
      all,
      linked: SubscriptionPayments.linkedIds(
          ref.read(subscriptionsProvider).valueOrNull ?? const []),
    );
    final Transaction? picked = await showModalBottomSheet<Transaction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DsSpacing.xl, 0, DsSpacing.xl, DsSpacing.sm),
              child: Text(
                  found.isEmpty ? l.subDueNoMatch : l.subDuePick,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final Transaction t in found.take(6))
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(MoneyFormatter.format(t.amount)),
                subtitle: Text(<String>[
                  dayText(locale, t.date),
                  if (t.description.trim().isNotEmpty) t.description.trim(),
                ].join(' · ')),
                onTap: () => Navigator.of(ctx).pop(t),
              ),
            const SizedBox(height: DsSpacing.md),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _run(() => ref
        .read(subscriptionActionsProvider)
        .linkCharge(widget.due.item, widget.due.date, picked));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    final Locale locale = Localizations.localeOf(context);
    final DueCharge d = widget.due;
    final RecurringRule rule = d.item.rule!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.help_outline_rounded, size: 18, color: c.warning),
              const SizedBox(width: DsSpacing.sm),
              Expanded(child: Text(l.subDueTitle, style: t.labelLarge)),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            l.subDueQuestion(d.item.sub.provider,
                MoneyFormatter.format(rule.amount), dayText(locale, d.date)),
            style: t.bodyMedium,
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              DsButton(
                label: l.subDueYes,
                icon: Icons.check_rounded,
                onPressed: _busy ? null : _yes,
              ),
              DsButton(
                label: l.subDueMine,
                variant: DsButtonVariant.secondary,
                onPressed: _busy ? null : _mine,
              ),
              DsButton(
                label: l.subDueNo,
                variant: DsButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => _run(() => ref
                        .read(subscriptionActionsProvider)
                        .skipCharge(d.item, d.date)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The amount actually charged (it may differ: a price change, fees), and
/// whether later renewals use it.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.amount});
  final Money amount;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _c =
      TextEditingController(text: AmountInput.text(widget.amount.asDouble));
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _forFuture = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _changed {
    final double? v = AmountInput.parse(_c.text);
    return v != null &&
        Money.fromDouble(v, widget.amount.currencyCode).minorUnits !=
            widget.amount.minorUnits;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.subDueAmountTitle),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DsTextField(
              label: l.fieldAmount,
              suffixText: widget.amount.currencyCode,
              controller: _c,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (String? v) =>
                  (AmountInput.parse(v ?? '') ?? 0) > 0
                      ? null
                      : l.valAmountInvalid,
            ),
            if (_changed)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _forFuture,
                onChanged: (bool? v) =>
                    setState(() => _forFuture = v ?? false),
                title: Text(l.subDueForFuture),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel)),
        TextButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.of(context).pop((
              amount: Money.fromDouble(AmountInput.parse(_c.text)!,
                  widget.amount.currencyCode),
              forFuture: _changed && _forFuture,
            ));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// On the dashboard, only while a subscription charge waits for an answer:
/// opens the subscriptions tab, where the questions are.
class SubscriptionDueBanner extends ConsumerWidget {
  const SubscriptionDueBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DueCharge> due = ref.watch(subscriptionDueProvider);
    if (due.isEmpty) return const SizedBox.shrink();
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.md),
      child: GlassCard(
        onTap: () => context.go('/recurring'),
        child: Row(
          children: <Widget>[
            Icon(Icons.subscriptions_outlined, color: c.warning),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Text(l.subDueBanner(due.length),
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
