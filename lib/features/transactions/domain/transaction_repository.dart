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

  /// Merge-imports [txns], skipping any whose id already exists (non-destructive
  /// restore). Returns the number of transactions actually added.
  Future<int> importMany(List<Transaction> txns);

  /// Removes every transaction whose id is in [ids]. Returns the count removed.
  Future<int> deleteMany(Iterable<String> ids);

  void dispose();
}
