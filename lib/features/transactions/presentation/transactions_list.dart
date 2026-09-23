import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A searchable, filterable list of transactions. When [type] is null it shows
/// income + expense with filter chips; otherwise it is locked to one kind.
class TransactionsListView extends ConsumerStatefulWidget {
  const TransactionsListView({super.key, this.type});

  final TransactionType? type;

  @override
  ConsumerState<TransactionsListView> createState() =>
      _TransactionsListViewState();
}

class _TransactionsListViewState extends ConsumerState<TransactionsListView> {
  final TextEditingController _search = TextEditingController();
  TransactionType? _filter; // used only when widget.type == null

  @override
  void initState() {
    super.initState();
    _filter = widget.type;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<List<Transaction>> async = ref.watch(transactionsProvider);

    return async.when(
      loading: () => const DsLoading(),
      error: (Object e, _) => DsError(message: e.toString()),
      data: (List<Transaction> all) {
        final TransactionType? effective = widget.type ?? _filter;
        final String q = _search.text.trim().toLowerCase();
        final List<Transaction> items = all.where((Transaction t) {
          if (effective != null && t.type != effective) return false;
          if (q.isEmpty) return true;
          return t.description.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SearchBar(controller: _search, onChanged: (_) => setState(() {})),
            if (widget.type == null) ...<Widget>[
              const SizedBox(height: DsSpacing.md),
              _FilterChips(
                value: _filter,
                onChanged: (TransactionType? v) => setState(() => _filter = v),
              ),
            ],
            const SizedBox(height: DsSpacing.md),
            Expanded(
              child: items.isEmpty
                  ? DsEmpty(
                      title: all.isEmpty
                          ? l.emptyTransactionsTitle
                          : l.noResults,
                      message: all.isEmpty ? l.emptyTransactionsMessage : null,
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DsSpacing.sm),
                      itemBuilder: (BuildContext context, int i) =>
                          TransactionTile(txn: items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: l.searchTransactions,
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: c.textFaint),
        filled: true,
        fillColor: c.surfaceMuted,
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: c.brand),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});
  final TransactionType? value;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    Widget chip(String label, TransactionType? v, Color color) {
      final bool selected = value == v;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onChanged(v),
          showCheckmark: false,
          backgroundColor: c.surfaceMuted,
          selectedColor: color.withValues(alpha: 0.18),
          side: BorderSide(color: selected ? color : c.border),
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : c.textMuted,
              ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        chip(l.filterAll, null, c.brand),
        chip(l.filterIncome, TransactionType.income, c.income),
        chip(l.filterExpense, TransactionType.expense, c.expense),
      ],
    );
  }
}

/// A single transaction row (tap to edit, menu to delete).
class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.txn});
  final Transaction txn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final Color accent = txn.isIncome ? c.income : c.expense;
    final String sign = txn.isIncome ? '+' : '−';
    final String category = Catalog.label(txn.category,
        ar: Localizations.localeOf(context).languageCode == 'ar');

    return Material(
      color: c.surface,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () =>
            TransactionEditorSheet.show(context, type: txn.type, existing: txn),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  txn.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      txn.description.isEmpty ? category : txn.description,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        if (RecurrenceEngine.isRecurring(txn)) ...<Widget>[
                          Tooltip(
                            message: l.recurringBadge,
                            child: Icon(Icons.event_repeat_outlined,
                                size: 12, color: c.textFaint),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            '$category · ${DateFormat('yyyy-MM-dd').format(txn.date)}',
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Text(
                '$sign ${MoneyFormatter.format(txn.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textFaint),
                color: c.bgElevated,
                onSelected: (String v) async {
                  if (v == 'edit') {
                    await TransactionEditorSheet.show(context,
                        type: txn.type, existing: txn);
                  } else if (v == 'delete') {
                    await _confirmDelete(context, ref, l);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                  PopupMenuItem<String>(value: 'delete', child: Text(l.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteTxnTitle),
        content: Text(l.deleteTxnBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(transactionActionsProvider).delete(txn.id);
    }
  }
}
