import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/dev/sample_data.dart';
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
/// stores, then focuses that year. Idempotent — re-running adds nothing new.
class SampleDataLoader {
  SampleDataLoader(this._ref);
  final Ref _ref;

  Future<SampleImportResult> load({int year = 2026}) async {
    final String currency = _ref.read(baseCurrencyProvider);
    final SampleDataSet data = SampleData.build(currency: currency, year: year);

    final int tx =
        await _ref.read(financeRepositoryProvider).importMany(data.transactions);
    final int bud =
        await _ref.read(budgetRepositoryProvider).importMany(data.budgets);

    _ref.read(selectedYearProvider.notifier).state = year;
    return SampleImportResult(transactionsAdded: tx, budgetsAdded: bud);
  }
}
