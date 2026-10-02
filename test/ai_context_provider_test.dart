import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/assistant/application/ask_ai_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/dev/sample_data.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

void main() {
  test('the assistant context carries the history and budgets by category',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_base_currency': 'USD',
    });
    final DateTime now = AppClock.now();
    final SampleDataSet data =
        SampleData.build(currency: 'USD', year: now.year);
    final ProviderContainer c = ProviderContainer(overrides: [
      transactionsProvider.overrideWith(
          (ref) => Stream<List<Transaction>>.value(data.transactions)),
      budgetsProvider.overrideWith(
          (ref) => Stream<List<BudgetTarget>>.value(data.budgets)),
      goalsProvider
          .overrideWith((ref) => Stream<List<Goal>>.value(data.goals)),
    ]);
    addTearDown(c.dispose);
    // Let the streams deliver.
    c.listen(transactionsProvider, (_, __) {});
    c.listen(budgetsProvider, (_, __) {});
    c.listen(goalsProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final String ctx = c.read(aiContextProvider);
    expect(ctx, contains('Monthly history (oldest first'));
    expect(ctx, contains('expenses by category:'));
    if (data.goals.isNotEmpty) expect(ctx, contains('Goals: #1 saved'));
    expect(ctx, isNot(contains('null')));
  });
}
