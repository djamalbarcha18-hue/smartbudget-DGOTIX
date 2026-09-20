import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Outcome of a restore, for user feedback.
class ImportResult {
  const ImportResult({
    required this.transactionsAdded,
    required this.budgetsAdded,
  });

  final int transactionsAdded;
  final int budgetsAdded;

  bool get isEmpty => transactionsAdded == 0 && budgetsAdded == 0;
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);

/// Gathers the current data into a [BackupData] snapshot and restores one back.
class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  /// Reads the live data (via the stream providers, so it reflects what the app
  /// currently shows) into a portable snapshot.
  BackupData snapshot() {
    final List<Transaction> txns =
        _ref.read(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final List<BudgetTarget> budgets =
        _ref.read(budgetsProvider).valueOrNull ?? const <BudgetTarget>[];
    final CustomCategories cc = _ref.read(customCategoriesProvider);
    return BackupData(
      exportedAt: DateTime.now(),
      baseCurrency: _ref.read(baseCurrencyProvider),
      transactions: txns,
      budgets: budgets,
      customIncome: cc.income,
      customExpense: cc.expense,
    );
  }

  String exportJson() => BackupCodec.encodeJson(snapshot());

  String exportTransactionsCsv() =>
      BackupCodec.transactionsToCsv(snapshot().transactions);

  /// Restores from a JSON backup string. Non-destructive: existing rows are
  /// kept, only new ones are merged in. Throws [FormatException] on bad input.
  Future<ImportResult> importJson(String raw) =>
      importData(BackupCodec.decodeJson(raw));

  /// Restores from an already-parsed [BackupData] (shared by file import and
  /// cloud restore). Non-destructive: only new rows are merged in.
  Future<ImportResult> importData(BackupData data) async {
    final int txAdded =
        await _ref.read(financeRepositoryProvider).importMany(data.transactions);
    final int budAdded =
        await _ref.read(budgetRepositoryProvider).importMany(data.budgets);
    await _ref.read(customCategoriesProvider.notifier).importMany(
          income: data.customIncome,
          expense: data.customExpense,
        );
    return ImportResult(transactionsAdded: txAdded, budgetsAdded: budAdded);
  }
}
