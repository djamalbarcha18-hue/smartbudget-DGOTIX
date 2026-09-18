import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/budget/data/fake_budget_repository.dart';
import 'package:smartbudget/features/budget/domain/budget_repository.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final BudgetRepository repo = FakeBudgetRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

final budgetsProvider = StreamProvider<List<BudgetTarget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAll();
});

/// Planned amount per category for the selected year+month.
final monthPlannedByCategoryProvider = Provider<Map<String, Money>>((ref) {
  final List<BudgetTarget> all =
      ref.watch(budgetsProvider).valueOrNull ?? const <BudgetTarget>[];
  final int year = ref.watch(selectedYearProvider);
  final int month = ref.watch(selectedMonthProvider);
  final Map<String, Money> out = <String, Money>{};
  for (final BudgetTarget b in all) {
    if (b.year == year && b.month == month) out[b.category] = b.planned;
  }
  return out;
});

/// Total planned expense for the selected year (all months, base currency).
/// Feeds the V1 budget-discipline health indicator.
final yearPlannedExpenseProvider = Provider<Money>((ref) {
  final List<BudgetTarget> all =
      ref.watch(budgetsProvider).valueOrNull ?? const <BudgetTarget>[];
  final int year = ref.watch(selectedYearProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  var total = 0;
  for (final BudgetTarget b in all) {
    if (b.year == year && b.planned.currencyCode == currency) {
      total += b.planned.minorUnits;
    }
  }
  return Money(total, currency);
});

final budgetActionsProvider = Provider<BudgetActions>((ref) {
  return BudgetActions(
    ref.watch(budgetRepositoryProvider),
    ref.watch(baseCurrencyProvider),
  );
});

class BudgetActions {
  BudgetActions(this._repo, this._currency);
  final BudgetRepository _repo;
  final String _currency;

  Future<void> setPlanned({
    required int year,
    required int month,
    required String category,
    required double amount,
  }) {
    return _repo.setPlanned(
      year: year,
      month: month,
      category: category,
      amount: amount,
      currencyCode: _currency,
    );
  }
}
