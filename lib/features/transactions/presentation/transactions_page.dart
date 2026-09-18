import 'package:flutter/widgets.dart';

import 'package:smartbudget/features/transactions/presentation/finance_screen.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FinanceScreen(title: AppLocalizations.of(context).pageTransactions);
  }
}
