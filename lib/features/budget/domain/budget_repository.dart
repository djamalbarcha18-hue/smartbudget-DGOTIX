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
  void dispose();
}
