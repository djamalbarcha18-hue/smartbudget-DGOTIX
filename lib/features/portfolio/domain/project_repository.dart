import 'package:smartbudget/features/portfolio/domain/project.dart';

/// Backend-agnostic projects-portfolio store (dev impl now; Supabase later).
abstract interface class ProjectRepository {
  Stream<List<Project>> watchAll();
  List<Project> get current;
  Future<void> add(Project project);
  Future<void> update(Project project);
  Future<void> delete(String id);
  void dispose();
}
