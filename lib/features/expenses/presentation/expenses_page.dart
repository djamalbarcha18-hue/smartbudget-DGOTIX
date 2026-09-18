import 'package:flutter/widgets.dart';

import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/finance_screen.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FinanceScreen(
      title: AppLocalizations.of(context).pageExpenses,
      type: TransactionType.expense,
    );
  }
}
