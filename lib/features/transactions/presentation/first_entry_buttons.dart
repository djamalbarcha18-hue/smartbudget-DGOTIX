import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What an empty page offers: add the first expense or income right there,
/// so nobody is left looking for where to start.
class FirstEntryButtons extends StatelessWidget {
  const FirstEntryButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.sm,
      children: <Widget>[
        DsButton(
          label: l.addExpense,
          icon: Icons.north_east_rounded,
          onPressed: () => TransactionEditorSheet.show(context,
              type: TransactionType.expense),
        ),
        DsButton(
          label: l.addIncome,
          icon: Icons.south_west_rounded,
          variant: DsButtonVariant.secondary,
          onPressed: () => TransactionEditorSheet.show(context,
              type: TransactionType.income),
        ),
      ],
    );
  }
}
