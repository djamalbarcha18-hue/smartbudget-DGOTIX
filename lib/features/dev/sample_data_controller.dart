import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/dev/sample_data.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';

class SampleImportResult {
  const SampleImportResult({
    required this.transactionsAdded,
    required this.budgetsAdded,
  });
  final int transactionsAdded;
  final int budgetsAdded;

  bool get isEmpty => transactionsAdded == 0 && budgetsAdded == 0;
}

final sampleDataLoaderProvider =
    Provider<SampleDataLoader>((ref) => SampleDataLoader(ref));

/// Loads deterministic demo data for a year (default 2026) into the active
/// stores, in the user's current base currency (never switching it), and
/// selects that year so the dashboard fills up.
/// Idempotent — re-running adds nothing new.
class SampleDataLoader {
  SampleDataLoader(this._ref);
  final Ref _ref;

  Future<SampleImportResult> load({int year = 2026}) async {
    final String base = _ref.read(baseCurrencyProvider);
    final double? perUsd = _ref.read(ratesProvider)[base];
    final SampleDataSet data =
        SampleData.build(currency: base, year: year, scale: perUsd ?? 1);

    final int tx = await _ref
        .read(financeRepositoryProvider)
        .importMany(data.transactions);
    final int bud =
        await _ref.read(budgetRepositoryProvider).importMany(data.budgets);
    await _ref.read(goalRepositoryProvider).importMany(data.goals);

    // Make the sample visible: the dashboard follows the selected year.
    _ref.read(selectedYearProvider.notifier).state = year;

    return SampleImportResult(transactionsAdded: tx, budgetsAdded: bud);
  }

  /// Removes exactly the sample rows for [year] (by their stable ids), leaving
  /// any of the user's own data untouched.
  Future<SampleImportResult> clear({int year = 2026}) async {
    // Removal goes by the stable ids, whatever currency they were made in.
    final SampleDataSet data = SampleData.build(currency: 'USD', year: year);

    final int tx = await _ref
        .read(financeRepositoryProvider)
        .deleteMany(data.transactions.map((t) => t.id));
    final int bud = await _ref
        .read(budgetRepositoryProvider)
        .deleteMany(data.budgets.map((b) => b.id));
    await _ref
        .read(goalRepositoryProvider)
        .deleteMany(data.goals.map((g) => g.id));

    return SampleImportResult(transactionsAdded: tx, budgetsAdded: bud);
  }
}
