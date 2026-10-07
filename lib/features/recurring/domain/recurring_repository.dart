import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';

/// Backend-agnostic store of recurring-transaction rules.
abstract interface class RecurringRepository {
  Stream<List<RecurringRule>> watchAll();
  List<RecurringRule> get current;
  Future<void> add(RecurringRule rule);
  Future<void> update(RecurringRule rule);

  /// Replaces every rule whose id matches one in [rules] in a single write.
  Future<void> updateMany(List<RecurringRule> rules);
  Future<void> delete(String id);

  /// Merge-imports [rules], skipping any whose id already exists. Returns the
  /// number actually added.
  Future<int> importMany(List<RecurringRule> rules);

  /// Makes the stored list exactly [items] (cloud sync applies a merged
  /// state with it).
  Future<void> replaceAll(List<RecurringRule> items);

  void dispose();
}
