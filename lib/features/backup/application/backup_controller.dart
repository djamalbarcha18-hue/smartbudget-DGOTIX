import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/challenges/application/challenges_controller.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/zakat/application/zakat_backup.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/application/zakat_history_controller.dart';

/// Outcome of a restore, for user feedback.
class ImportResult {
  const ImportResult({
    required this.transactionsAdded,
    required this.budgetsAdded,
    this.goalsAdded = 0,
    this.debtsAdded = 0,
    this.projectsAdded = 0,
    this.recurringAdded = 0,
    this.othersAdded = 0,
  });

  final int transactionsAdded;
  final int budgetsAdded;
  final int goalsAdded;
  final int debtsAdded;
  final int projectsAdded;
  final int recurringAdded;

  /// Season plans, darets and other planning items.
  final int othersAdded;

  /// Goals, debts, projects and recurring rules restored (shown together in
  /// the message).
  int get plansAdded =>
      goalsAdded + debtsAdded + projectsAdded + recurringAdded + othersAdded;

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
      seasons: await _ref.read(seasonStoreProvider).all(),
      darets: await _ref.read(daretStoreProvider).all(),
      challenges: await _ref.read(challengeStoreProvider).all(),
      wallets: await _ref.read(walletStoreProvider).all(),
      walletMoves: await _ref.read(walletMoveStoreProvider).all(),
      trips: await _ref.read(tripStoreProvider).all(),
      metals: await _ref.read(metalStoreProvider).all(),
      metalSales: await _ref.read(metalSaleStoreProvider).all(),
      exportedAt: AppClock.now(),
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

  /// The backup file: [snapshot] plus the zakat settings and history (kept
  /// on the device only, so the file is their one copy elsewhere). Cloud
  /// sync uses [snapshot] alone and is unchanged.
  Future<String> exportJson() async {
    final Map<String, dynamic> json = (await snapshot()).toJson();
    try {
      final Map<String, dynamic>? zakat = ZakatBackupIo.export(
          await SharedPreferences.getInstance(),
          _ref.read(currentAccountIdProvider),
          _ref.read(baseCurrencyProvider));
      if (zakat != null) json[ZakatBackupIo.section] = zakat;
    } catch (_) {
      // The rest of the backup doesn't depend on it.
    }
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<String> exportTransactionsCsv() async =>
      BackupCodec.transactionsToCsv((await snapshot()).transactions);

  /// Restores from a JSON backup string. Non-destructive: existing rows are
  /// kept, only new ones are merged in. Throws [FormatException] on bad input.
  Future<ImportResult> importJson(String raw) async {
    final ImportResult result = await importData(BackupCodec.decodeJson(raw));
    int zakatAdded = 0;
    try {
      final Object? file = jsonDecode(raw);
      if (file is Map<String, dynamic>) {
        zakatAdded = await ZakatBackupIo.import(
            await SharedPreferences.getInstance(),
            _ref.read(currentAccountIdProvider),
            file);
        _ref.invalidate(zakatSettingsProvider);
        _ref.invalidate(zakatHistoryProvider);
      }
    } catch (_) {
      // The rest is restored; the zakat part is optional.
    }
    if (zakatAdded == 0) return result;
    return ImportResult(
      othersAdded: result.othersAdded + zakatAdded,
      transactionsAdded: result.transactionsAdded,
      budgetsAdded: result.budgetsAdded,
      goalsAdded: result.goalsAdded,
      debtsAdded: result.debtsAdded,
      projectsAdded: result.projectsAdded,
      recurringAdded: result.recurringAdded,
    );
  }

  /// Makes the device hold exactly [data] (cloud sync applies a merged state
  /// with it). The base currency is set only when [setBaseCurrency].
  Future<void> replaceAll(BackupData data, {bool setBaseCurrency = true}) async {
    await _ref.read(financeRepositoryProvider).replaceAll(data.transactions);
    await _ref.read(budgetRepositoryProvider).replaceAll(data.budgets);
    await _ref.read(goalRepositoryProvider).replaceAll(data.goals);
    await _ref.read(debtRepositoryProvider).replaceAll(data.debts);
    await _ref.read(projectRepositoryProvider).replaceAll(data.projects);
    await _ref.read(recurringRepositoryProvider).replaceAll(data.recurring);
    await _ref.read(customCategoriesProvider.notifier).replaceAll(
          income: data.customIncome,
          expense: data.customExpense,
        );
    await _ref.read(seasonStoreProvider).replaceAll(data.seasons);
    await _ref.read(daretStoreProvider).replaceAll(data.darets);
    await _ref.read(challengeStoreProvider).replaceAll(data.challenges);
    await _ref.read(walletStoreProvider).replaceAll(data.wallets);
    await _ref.read(walletMoveStoreProvider).replaceAll(data.walletMoves);
    await _ref.read(tripStoreProvider).replaceAll(data.trips);
    await _ref.read(metalStoreProvider).replaceAll(data.metals);
    await _ref.read(metalSaleStoreProvider).replaceAll(data.metalSales);
    if (setBaseCurrency &&
        data.baseCurrency != _ref.read(baseCurrencyProvider)) {
      await _ref.read(baseCurrencyProvider.notifier).set(data.baseCurrency);
    }
  }

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
    final int othersAdded =
        await _ref.read(seasonStoreProvider).importMany(data.seasons) +
            await _ref.read(daretStoreProvider).importMany(data.darets) +
            await _ref.read(challengeStoreProvider).importMany(data.challenges) +
            await _ref.read(walletStoreProvider).importMany(data.wallets) +
            await _ref.read(walletMoveStoreProvider).importMany(data.walletMoves) +
            await _ref.read(tripStoreProvider).importMany(data.trips) +
            await _ref.read(metalStoreProvider).importMany(data.metals) +
            await _ref.read(metalSaleStoreProvider).importMany(data.metalSales);
    return ImportResult(
      othersAdded: othersAdded,
      transactionsAdded: txAdded,
      budgetsAdded: budAdded,
      goalsAdded: goalsAdded,
      debtsAdded: debtsAdded,
      projectsAdded: projectsAdded,
      recurringAdded: recurringAdded,
    );
  }
}
