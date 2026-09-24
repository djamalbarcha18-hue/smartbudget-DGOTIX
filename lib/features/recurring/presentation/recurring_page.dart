import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Lists the user's recurring transactions with their next date and lets them
/// pause, resume, edit or stop each one.
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final DsColors c = context.dsColors;
    final AsyncValue<List<RecurringRule>> async =
        ref.watch(recurringRulesProvider);

    final List<Widget> addButtons = <Widget>[
      DsButton(
        label: l.addIncome,
        icon: Icons.south_west_rounded,
        variant: DsButtonVariant.secondary,
        onPressed: () => TransactionEditorSheet.show(context,
            type: TransactionType.income,
            initialRepeat: RecurrenceFrequency.monthly),
      ),
      DsButton(
        label: l.addExpense,
        icon: Icons.north_east_rounded,
        onPressed: () => TransactionEditorSheet.show(context,
            type: TransactionType.expense,
            initialRepeat: RecurrenceFrequency.monthly),
      ),
    ];

    return async.when(
      loading: () => const DsLoading(),
      error: (Object e, _) => DsError(message: e.toString()),
      data: (List<RecurringRule> rules) => ListView(
        padding: const EdgeInsets.all(DsSpacing.pageGutter),
        children: <Widget>[
          if (context.isMobile) ...<Widget>[
            Text(l.navRecurring, style: t.headlineSmall),
            const SizedBox(height: DsSpacing.md),
            Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: addButtons),
          ] else
            Row(
              children: <Widget>[
                Expanded(child: Text(l.navRecurring, style: t.headlineSmall)),
                for (final Widget b in addButtons) ...<Widget>[
                  b,
                  const SizedBox(width: DsSpacing.sm),
                ],
              ],
            ),
          const SizedBox(height: DsSpacing.sm),
          Text(l.recurringIntro,
              style: t.bodyMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.lg),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xl),
              child: DsEmpty(
                title: l.navRecurring,
                message: l.recurringEmpty,
                icon: Icons.event_repeat_outlined,
              ),
            )
          else ...<Widget>[
            _Totals(rules: rules),
            const SizedBox(height: DsSpacing.lg),
            for (final RecurringRule r in rules) ...<Widget>[
              _RuleCard(rule: r),
              const SizedBox(height: DsSpacing.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _Totals extends ConsumerWidget {
  const _Totals({required this.rules});
  final List<RecurringRule> rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = ref.watch(baseCurrencyProvider);
    final Money income =
        RecurrenceEngine.monthlyTotal(rules, TransactionType.income, currency);
    final Money expense =
        RecurrenceEngine.monthlyTotal(rules, TransactionType.expense, currency);

    Widget tile(String label, Money m, Color color) => Expanded(
          child: GlassCard(
            accent: color,
            tintBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: t.labelMedium?.copyWith(color: c.textMuted)),
                const SizedBox(height: DsSpacing.xs),
                Text(MoneyFormatter.format(m),
                    style: t.titleLarge?.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            tile(l.recurringMonthlyIncome, income, c.income),
            const SizedBox(width: DsSpacing.md),
            tile(l.recurringMonthlyExpense, expense, c.expense),
          ],
        ),
        const SizedBox(height: DsSpacing.sm),
        Text(l.recurringMonthlyNote,
            style: t.labelSmall?.copyWith(color: c.textFaint)),
      ],
    );
  }
}

class _RuleCard extends ConsumerWidget {
  const _RuleCard({required this.rule});
  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final Color accent = rule.isIncome ? c.income : c.expense;
    final String category = Catalog.label(rule.category, ar: ar);
    final String title =
        rule.description.isEmpty ? category : rule.description;
    final String next = DateFormat('yyyy-MM-dd')
        .format(RecurrenceEngine.nextOccurrence(rule));
    final RecurringActions actions = ref.read(recurringActionsProvider);

    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md, vertical: DsSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: rule.active ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_repeat_outlined,
                color: rule.active ? accent : c.textFaint, size: 18),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${repeatLabel(l, rule.frequency)} · $category',
                    style: t.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (rule.active)
                  Text(l.recurringNext(next),
                      style: t.labelSmall?.copyWith(color: c.textMuted))
                else
                  DsBadge(label: l.recurringPaused, tone: DsBadgeTone.warning),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(
            '${rule.isIncome ? '+' : '−'} ${MoneyFormatter.format(rule.amount)}',
            style: t.titleSmall?.copyWith(
              color: rule.active ? accent : c.textFaint,
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
            color: c.bgElevated,
            onSelected: (String v) async {
              switch (v) {
                case 'edit':
                  await _RuleEditDialog.show(context, rule);
                case 'pause':
                  await actions.pause(rule);
                case 'resume':
                  await actions.resume(rule);
                case 'stop':
                  if (await _confirmStop(context, l)) {
                    await actions.stop(rule);
                  }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
              if (rule.active)
                PopupMenuItem<String>(
                    value: 'pause', child: Text(l.recurringPause))
              else
                PopupMenuItem<String>(
                    value: 'resume', child: Text(l.recurringResume)),
              PopupMenuItem<String>(value: 'stop', child: Text(l.recurringStop)),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmStop(BuildContext context, AppLocalizations l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.recurringStopTitle),
        content: Text(l.recurringStopBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.recurringStop),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

/// Edits the amount and description future occurrences will use.
class _RuleEditDialog extends ConsumerStatefulWidget {
  const _RuleEditDialog({required this.rule});
  final RecurringRule rule;

  static Future<void> show(BuildContext context, RecurringRule rule) =>
      showDialog<void>(
        context: context,
        builder: (_) => _RuleEditDialog(rule: rule),
      );

  @override
  ConsumerState<_RuleEditDialog> createState() => _RuleEditDialogState();
}

class _RuleEditDialogState extends ConsumerState<_RuleEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: widget.rule.amount.asDouble.toString());
  late final TextEditingController _description =
      TextEditingController(text: widget.rule.description);
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final double amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;
    await ref.read(recurringActionsProvider).editTemplate(
          widget.rule,
          amount:
              Money.fromDouble(amount, widget.rule.amount.currencyCode),
          description: _description.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return AlertDialog(
      title: Text(l.recurringEditTitle),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DsTextField(
                label:
                    '${l.fieldAmount} (${widget.rule.amount.currency.symbol})',
                controller: _amount,
                prefixIcon: Icons.tag_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (String? v) {
                  final double n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.')) ??
                      0;
                  return n > 0 ? null : l.valAmountInvalid;
                },
              ),
              const SizedBox(height: DsSpacing.lg),
              DsTextField(
                label: '${l.fieldDescription} (${l.optional})',
                controller: _description,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: DsSpacing.md),
              Text(l.recurringEditHint,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: c.textFaint)),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}
