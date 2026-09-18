import 'package:smartbudget/features/goals/domain/goal.dart';

/// Backend-agnostic goals store (dev impl in P4; Supabase later).
abstract interface class GoalRepository {
  Stream<List<Goal>> watchAll();
  List<Goal> get current;
  Future<void> add(Goal goal);
  Future<void> update(Goal goal);
  Future<void> delete(String id);

  /// Merge-imports [goals], skipping any whose id already exists. Returns the
  /// number actually added.
  Future<int> importMany(List<Goal> goals);

  /// Removes every goal whose id is in [ids]. Returns the count removed.
  Future<int> deleteMany(Iterable<String> ids);

  void dispose();
}
