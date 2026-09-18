import 'package:smartbudget/features/goals/domain/goal.dart';

/// Backend-agnostic goals store (dev impl in P4; Supabase later).
abstract interface class GoalRepository {
  Stream<List<Goal>> watchAll();
  List<Goal> get current;
  Future<void> add(Goal goal);
  Future<void> update(Goal goal);
  Future<void> delete(String id);
  void dispose();
}
