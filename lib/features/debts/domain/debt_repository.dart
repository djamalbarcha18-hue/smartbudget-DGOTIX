import 'package:smartbudget/features/debts/domain/debt.dart';

/// Backend-agnostic debts store (dev impl in P4; Supabase later).
abstract interface class DebtRepository {
  Stream<List<Debt>> watchAll();
  List<Debt> get current;
  Future<void> add(Debt debt);
  Future<void> update(Debt debt);
  Future<void> delete(String id);

  /// Restores [debts] from a backup. Non-destructive: rows whose id already
  /// exists are kept as they are. Returns how many were added.
  Future<int> importMany(List<Debt> debts);
  void dispose();
}
