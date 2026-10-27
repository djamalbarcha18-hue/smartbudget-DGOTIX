import 'dart:async';

import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/save_health.dart';

import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/portfolio/domain/project_repository.dart';

/// Per-user device-local projects store for development.
class FakeProjectRepository implements ProjectRepository {
  FakeProjectRepository({required this.userId}) {
    _controller =
        StreamController<List<Project>>.broadcast(onListen: _emitInitial);
  }

  final String userId;
  late final StreamController<List<Project>> _controller;
  final List<Project> _items = <Project>[];
  Future<void>? _loading;

  String get _key => 'sb_projects_$userId';

  @override
  List<Project> get current => List<Project>.unmodifiable(_items);

  @override
  Stream<List<Project>> watchAll() => _controller.stream;

  Future<void> _emitInitial() async {
    await _load();
    _emit();
  }

  /// Loads once; every caller waits for that same load, so none sees an
  /// empty list while it runs (a sync round would take that for deletions).
  Future<void> _load() => _loading ??= _loadNow();

  Future<void> _loadNow() async {
    try {
      // Unreadable entries are skipped, never the whole list.
      final List<Project> stored =
          await RecordLists.current.load(_key, Project.fromJson);
      if (stored.isNotEmpty) {
        _items
          ..clear()
          ..addAll(stored);
        _sort();
      }
    } catch (_) {
      // Start empty.
    }
  }

  @override
  Future<void> add(Project project) async {
    await _load();
    _items.add(project);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<void> update(Project project) async {
    await _load();
    final int i = _items.indexWhere((Project p) => p.id == project.id);
    if (i != -1) {
      _items[i] = project;
      _sort();
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((Project p) => p.id == id);
    await _persist();
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<void> replaceAll(List<Project> items) async {
    await _load();
    _items
      ..clear()
      ..addAll(items);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<int> importMany(List<Project> projects) async {
    await _load();
    final Set<String> existing = _items.map((Project x) => x.id).toSet();
    int added = 0;
    for (final Project p in projects) {
      if (p.id.isEmpty || existing.contains(p.id)) continue;
      _items.add(p);
      existing.add(p.id);
      added++;
    }
    if (added > 0) {
      _sort();
      await _persist();
      _emit();
    }
    return added;
  }

  void _sort() {
    _items.sort((Project a, Project b) => a.createdAt.compareTo(b.createdAt));
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      await RecordLists.current.save(
          _key, _items.map((Project p) => p.toJson()).toList());
      SaveHealth.saved(_key);
    } catch (_) {
      // The user is told and can try again (SaveHealth).
      SaveHealth.failed(_key, _persist);
    }
  }
}
