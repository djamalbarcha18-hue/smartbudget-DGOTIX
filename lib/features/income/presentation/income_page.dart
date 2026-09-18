import 'package:flutter/widgets.dart';

import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/finance_screen.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FinanceScreen(
      title: AppLocalizations.of(context).pageIncome,
      type: TransactionType.income,
    );
  }
}
