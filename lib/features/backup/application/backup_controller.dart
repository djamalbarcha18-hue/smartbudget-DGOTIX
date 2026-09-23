import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Outcome of a restore, for user feedback.
class ImportResult {
  const ImportResult({
    required this.transactionsAdded,
    required this.budgetsAdded,
    this.goalsAdded = 0,
    this.debtsAdded = 0,
    this.projectsAdded = 0,
    this.recurringAdded = 0,
  });

  final int transactionsAdded;
  final int budgetsAdded;
  final int goalsAdded;
  final int debtsAdded;
  final int projectsAdded;
  final int recurringAdded;

  /// Goals, debts, projects and recurring rules restored (shown together in
  /// the message).
  int get plansAdded =>
      goalsAdded + debtsAdded + projectsAdded + recurringAdded;

  bool get isEmpty =>
      transactionsAdded == 0 && budgetsAdded == 0 && plansAdded == 0;
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);

/// Gathers the current data into a [BackupData] snapshot and restores one back.
class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  /// A complete, portable snapshot of everything the user has entered.
  ///
  /// Waits for every store to finish loading first, so the backup is complete
  /// even for screens the user hasn't opened in this session.
  Future<BackupData> snapshot() async {
    final List<Transaction> txns = await _ref.read(transactionsProvider.future);
    final List<BudgetTarget> budgets = await _ref.read(budgetsProvider.future);
    final List<Goal> goals = await _ref.read(goalsProvider.future);
    final List<Debt> debts = await _ref.read(debtsProvider.future);
    final List<Project> projects = await _ref.read(projectsProvider.future);
    final List<RecurringRule> recurring =
        await _ref.read(recurringRulesProvider.future);
    final CustomCategories cc = _ref.read(customCategoriesProvider);
    return BackupData(
      exportedAt: DateTime.now(),
      baseCurrency: _ref.read(baseCurrencyProvider),
      transactions: txns,
      budgets: budgets,
      customIncome: cc.income,
      customExpense: cc.expense,
      goals: goals,
      debts: debts,
      projects: projects,
      recurring: recurring,
    );
  }

  Future<String> exportJson() async => BackupCodec.encodeJson(await snapshot());

  Future<String> exportTransactionsCsv() async =>
      BackupCodec.transactionsToCsv((await snapshot()).transactions);

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
    final int goalsAdded =
        await _ref.read(goalRepositoryProvider).importMany(data.goals);
    final int debtsAdded =
        await _ref.read(debtRepositoryProvider).importMany(data.debts);
    final int projectsAdded =
        await _ref.read(projectRepositoryProvider).importMany(data.projects);
    final int recurringAdded = await _ref
        .read(recurringRepositoryProvider)
        .importMany(data.recurring);
    return ImportResult(
      transactionsAdded: txAdded,
      budgetsAdded: budAdded,
      goalsAdded: goalsAdded,
      debtsAdded: debtsAdded,
      projectsAdded: projectsAdded,
      recurringAdded: recurringAdded,
    );
  }
}
