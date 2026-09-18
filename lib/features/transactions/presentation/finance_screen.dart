import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_list.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Shared screen for Transactions / Income / Expenses: a title, quick-add
/// action(s) appropriate to [type], and the searchable list below.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key, required this.title, this.type});

  final String title;
  final TransactionType? type;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isMobile = context.isMobile;

    final List<Widget> addButtons = <Widget>[
      if (type == null || type == TransactionType.income)
        DsButton(
          label: l.addIncome,
          icon: Icons.south_west_rounded,
          variant: type == null
              ? DsButtonVariant.secondary
              : DsButtonVariant.primary,
          onPressed: () => TransactionEditorSheet.show(
            context,
            type: TransactionType.income,
          ),
        ),
      if (type == null || type == TransactionType.expense)
        DsButton(
          label: l.addExpense,
          icon: Icons.north_east_rounded,
          variant: type == null
              ? DsButtonVariant.secondary
              : DsButtonVariant.primary,
          onPressed: () => TransactionEditorSheet.show(
            context,
            type: TransactionType.expense,
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isMobile) ...<Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DsSpacing.md),
            Wrap(spacing: DsSpacing.sm, runSpacing: DsSpacing.sm, children: addButtons),
          ] else
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                for (final Widget b in addButtons) ...<Widget>[
                  b,
                  const SizedBox(width: DsSpacing.sm),
                ],
              ],
            ),
          const SizedBox(height: DsSpacing.lg),
          Expanded(child: TransactionsListView(type: type)),
        ],
      ),
    );
  }
}
