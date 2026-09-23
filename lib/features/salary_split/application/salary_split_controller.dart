import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/salary_split/domain/salary_split.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Everything the split needs, for the month selected on the budget screen.
class SplitInputs {
  const SplitInputs({
    required this.transactions,
    required this.goals,
    required this.year,
    required this.month,
    required this.defaultIncome,
  });

  final List<Transaction> transactions;
  final List<Goal> goals;
  final int year;
  final int month;

  /// Suggested starting income (the user can change it before splitting).
  final Money defaultIncome;

  SalarySplit splitFor(Money income) => SalarySplitEngine.compute(
        income: income,
        transactions: transactions,
        goals: goals,
        year: year,
        month: month,
      );
}

final salarySplitInputsProvider = Provider<SplitInputs>((ref) {
  final List<Transaction> txns =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  final int year = ref.watch(selectedYearProvider);
  final int month = ref.watch(selectedMonthProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return SplitInputs(
    transactions: txns,
    goals: goals,
    year: year,
    month: month,
    defaultIncome: SalarySplitEngine.defaultIncome(
        transactions: txns, year: year, month: month, currency: currency),
  );
});

/// Writes a split into the monthly budget. Only categories with a non-zero
/// suggestion are set; other categories keep whatever they had. Returns how
/// many categories were updated.
Future<int> applySalarySplit(
  WidgetRef ref, {
  required SalarySplit split,
  required int year,
  required int month,
}) async {
  final BudgetActions actions = ref.read(budgetActionsProvider);
  int count = 0;
  for (final SplitLine line in split.lines) {
    if (line.suggested.minorUnits <= 0) continue;
    await actions.setPlanned(
      year: year,
      month: month,
      category: line.category,
      amount: line.suggested.asDouble,
    );
    count++;
  }
  return count;
}
