import 'package:smartbudget/features/budget/domain/budget_target.dart';

/// Backend-agnostic budget-targets store (dev impl in P5; Supabase later).
abstract interface class BudgetRepository {
  Stream<List<BudgetTarget>> watchAll();
  List<BudgetTarget> get current;

  /// Upsert a target for (year, month, category). A non-positive amount removes
  /// it. [currencyCode] is the base currency for the stored amount.
  Future<void> setPlanned({
    required int year,
    required int month,
    required String category,
    required double amount,
    required String currencyCode,
  });

  Future<void> delete(String id);

  /// Merge-imports [targets], skipping any that collide with an existing
  /// (year, month, category). Returns the number actually added.
  Future<int> importMany(List<BudgetTarget> targets);

  /// Removes every target whose id is in [ids]. Returns the count removed.
  Future<int> deleteMany(Iterable<String> ids);

  void dispose();
}
