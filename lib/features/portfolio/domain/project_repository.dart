import 'package:smartbudget/features/portfolio/domain/project.dart';

/// Backend-agnostic projects-portfolio store (dev impl now; Supabase later).
abstract interface class ProjectRepository {
  Stream<List<Project>> watchAll();
  List<Project> get current;
  Future<void> add(Project project);
  Future<void> update(Project project);
  Future<void> delete(String id);

  /// Restores [projects] from a backup. Non-destructive: rows whose id already
  /// exists are kept as they are. Returns how many were added.
  Future<int> importMany(List<Project> projects);
  void dispose();
}
