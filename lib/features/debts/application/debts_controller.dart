import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/debts/data/fake_debt_repository.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/debts/domain/debt_repository.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final DebtRepository repo = FakeDebtRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

final debtsProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(debtRepositoryProvider).watchAll();
});

final debtSummaryProvider = Provider<DebtSummary>((ref) {
  final List<Debt> debts =
      ref.watch(debtsProvider).valueOrNull ?? const <Debt>[];
  final String currency = ref.watch(baseCurrencyProvider);
  return DebtCalculator.summary(debts, currency);
});

final debtActionsProvider = Provider<DebtActions>((ref) {
  return DebtActions(ref.watch(debtRepositoryProvider));
});

class DebtActions {
  DebtActions(this._repo);
  final DebtRepository _repo;

  Future<void> add(Debt d) => _repo.add(d);
  Future<void> update(Debt d) => _repo.update(d);
  Future<void> delete(String id) => _repo.delete(id);

  static String newId() =>
      'debt-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
