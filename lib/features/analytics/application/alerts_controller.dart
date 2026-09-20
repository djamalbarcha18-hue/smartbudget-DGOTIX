import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// A short-lived "highlight this element" target, set when the user opens an
/// alert's page so the destination can briefly emphasize the related item.
class AlertFocus {
  const AlertFocus({required this.route, required this.key});
  final String route;
  final String key;
}

/// Holds the current highlight target (null when nothing is focused). Cleared a
/// few seconds after navigation.
final alertFocusProvider = StateProvider<AlertFocus?>((ref) => null);

/// Live, data-backed alerts derived from budgets (selected month), the year's
/// cash-flow summary and goals. Recomputes automatically as data changes.
final alertsProvider = Provider<List<AppAlert>>((ref) {
  final Map<String, Money> planned = ref.watch(monthPlannedByCategoryProvider);
  final List<CategoryTotal> actual =
      ref.watch(monthExpenseCategoryTotalsProvider);
  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  final FinanceSummary summary = ref.watch(financeSummaryProvider);
  final String currency = ref.watch(baseCurrencyProvider);

  return AlertEngine.build(
    plannedByCategory: <String, int>{
      for (final MapEntry<String, Money> e in planned.entries)
        e.key: e.value.minorUnits,
    },
    actualByCategory: <String, int>{
      for (final CategoryTotal t in actual) t.category: t.amount.minorUnits,
    },
    goals: goals,
    yearSummary: summary,
    currency: currency,
  );
});
