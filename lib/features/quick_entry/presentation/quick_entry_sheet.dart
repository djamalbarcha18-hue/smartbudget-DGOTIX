import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Quick entry": type "قهوة 200" (or several, separated by «،») and save.
class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const QuickEntrySheet(),
      ),
    );
  }

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  final TextEditingController _text = TextEditingController();
  List<QuickEntry> _entries = const <QuickEntry>[];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _parse(String v) {
    final CustomCategories cc = ref.read(customCategoriesProvider);
    setState(() => _entries = QuickEntryParser.parseAll(v,
        today: AppClock.now(),
        customIncome: cc.income,
        customExpense: cc.expense));
  }

  Future<void> _save(AppLocalizations l) async {
    if (_entries.isEmpty) return;
    final String currency = ref.read(baseCurrencyProvider);
    final TransactionActions actions = ref.read(transactionActionsProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<String> ids = <String>[];
    for (final QuickEntry e in _entries) {
      final String id = '${TransactionActions.newId()}-${ids.length}';
      ids.add(id);
      await actions.add(Transaction(
        id: id,
        date: e.date,
        type: e.type,
        category: e.category,
        amount: Money.fromDouble(e.amount, currency),
        description: e.description,
        createdAt: AppClock.now(),
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(l.quickAdded(ids.length)),
      action: SnackBarAction(
        label: l.quickUndo,
        onPressed: () {
          for (final String id in ids) {
            actions.delete(id);
          }
        },
      ),
    ));
  }

  void _details() {
    final QuickEntry e = _entries.single;
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    TransactionEditorSheet.show(
      nav.context,
      type: e.type,
      prefill: TransactionDraft(
        amount: e.amount,
        category: e.recognized ? e.category : null,
        date: e.date,
        description: e.description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final String currency = ref.watch(baseCurrencyProvider);
    final DateTime today = AppClock.now();

    String dayLabel(DateTime d) {
      final int diff = DateTime(today.year, today.month, today.day)
          .difference(d)
          .inDays;
      return switch (diff) {
        0 => l.quickToday,
        1 => l.quickYesterday,
        _ => '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069',
      };
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.bolt_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.quickTitle,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(l.quickHint,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.md),
              TextField(
                controller: _text,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: _parse,
                onSubmitted: (_) => _save(l),
                decoration: InputDecoration(
                  hintText: l.quickExample,
                  prefixIcon: Icon(Icons.edit_note_rounded, color: c.textMuted),
                  border: const OutlineInputBorder(borderRadius: DsRadius.brMd),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              for (final QuickEntry e in _entries)
                Container(
                  margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: DsRadius.brMd,
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        e.type == TransactionType.income
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 18,
                        color: e.type == TransactionType.income
                            ? c.income
                            : c.expense,
                      ),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              Catalog.label(e.category, ar: ar),
                              style: t.titleSmall?.copyWith(
                                  color: e.recognized ? null : c.warning),
                            ),
                            Text(
                              <String>[
                                if (e.description.isNotEmpty) e.description,
                                dayLabel(e.date),
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  t.bodySmall?.copyWith(color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        MoneyFormatter.format(
                            Money.fromDouble(e.amount, currency)),
                        style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: e.type == TransactionType.income
                                ? c.income
                                : c.expense),
                      ),
                    ],
                  ),
                ),
              if (_entries.any((QuickEntry e) => !e.recognized))
                Padding(
                  padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                  child: Text(l.quickUnrecognized,
                      style: t.labelSmall?.copyWith(color: c.warning)),
                ),
              const SizedBox(height: DsSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DsButton(
                      label: _entries.length > 1
                          ? l.quickSaveN(_entries.length)
                          : l.save,
                      icon: Icons.check_rounded,
                      onPressed: _entries.isEmpty ? null : () => _save(l),
                    ),
                  ),
                  if (_entries.length == 1) ...<Widget>[
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: DsButton(
                        label: l.quickDetails,
                        icon: Icons.tune_rounded,
                        variant: DsButtonVariant.secondary,
                        onPressed: _details,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
