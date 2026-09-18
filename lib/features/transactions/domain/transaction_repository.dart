import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Backend-agnostic transactions store.
///
/// The UI and calculators depend only on this interface. P3 ships an in-memory
/// dev implementation; the Supabase implementation plugs in later with no UI or
/// business-logic changes.
abstract interface class TransactionRepository {
  /// Current list (newest first) and every change after.
  Stream<List<Transaction>> watchAll();

  /// Snapshot of the current list.
  List<Transaction> get current;

  Future<void> add(Transaction txn);
  Future<void> update(Transaction txn);
  Future<void> delete(String id);

  void dispose();
}
