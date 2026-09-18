import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/dev/sample_data.dart';
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

/// The sample data is always generated in USD so it shows up regardless of the
/// user's previous currency; loading it also switches the template to USD.
const String _sampleCurrency = 'USD';

final sampleDataLoaderProvider =
    Provider<SampleDataLoader>((ref) => SampleDataLoader(ref));

/// Loads deterministic demo data for a year (default 2026) into the active
/// stores, switches the template to USD + that year, so the dashboard fills up.
/// Idempotent — re-running adds nothing new.
class SampleDataLoader {
  SampleDataLoader(this._ref);
  final Ref _ref;

  Future<SampleImportResult> load({int year = 2026}) async {
    final SampleDataSet data =
        SampleData.build(currency: _sampleCurrency, year: year);

    final int tx =
        await _ref.read(financeRepositoryProvider).importMany(data.transactions);
    final int bud =
        await _ref.read(budgetRepositoryProvider).importMany(data.budgets);
    await _ref.read(goalRepositoryProvider).importMany(data.goals);

    // Make the sample visible: dashboard/summary filter by the base currency
    // and the selected year.
    await _ref
        .read(baseCurrencyProvider.notifier)
        .set(Currencies.usd.code);
    _ref.read(selectedYearProvider.notifier).state = year;

    return SampleImportResult(transactionsAdded: tx, budgetsAdded: bud);
  }

  /// Removes exactly the sample rows for [year] (by their stable ids), leaving
  /// any of the user's own data untouched.
  Future<SampleImportResult> clear({int year = 2026}) async {
    final SampleDataSet data =
        SampleData.build(currency: _sampleCurrency, year: year);

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
