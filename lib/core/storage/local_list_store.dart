import 'dart:async';

import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/save_health.dart';

/// A small per-key list kept on the device ([RecordLists]), with a live
/// stream. Items are identified by [idOf]; order is kept by [compare].
class LocalListStore<T> {
  LocalListStore({
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    this.compare,
  }) {
    _controller = StreamController<List<T>>.broadcast(onListen: _emitInitial);
  }

  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final String Function(T) idOf;
  final int Function(T, T)? compare;

  late final StreamController<List<T>> _controller;
  final List<T> _items = <T>[];
  Future<void>? _loading;

  List<T> get current => List<T>.unmodifiable(_items);

  Stream<List<T>> watchAll() => _controller.stream;

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
      final List<T> stored = await RecordLists.current.load(key, fromJson);
      if (stored.isNotEmpty) {
        _items
          ..clear()
          ..addAll(stored);
        _sort();
      }
    } catch (_) {
      // Corrupt/absent store — start empty.
    }
  }

  /// Everything, once loaded (for backups).
  Future<List<T>> all() async {
    await _load();
    return current;
  }

  Future<void> upsert(T item) async {
    await _load();
    final int i = _items.indexWhere((T x) => idOf(x) == idOf(item));
    if (i == -1) {
      _items.add(item);
    } else {
      _items[i] = item;
    }
    await _commit();
  }

  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((T x) => idOf(x) == id);
    await _commit();
  }

  /// Merge-imports [items], skipping ids that already exist.
  /// Makes the stored list exactly [items] (cloud sync applies a merged
  /// state with it).
  Future<void> replaceAll(List<T> items) async {
    await _load();
    _items
      ..clear()
      ..addAll(items);
    await _commit();
  }

  Future<int> importMany(List<T> items) async {
    await _load();
    final Set<String> ids = _items.map(idOf).toSet();
    int added = 0;
    for (final T x in items) {
      final String id = idOf(x);
      if (id.isEmpty || !ids.add(id)) continue;
      _items.add(x);
      added++;
    }
    if (added > 0) await _commit();
    return added;
  }

  void dispose() => _controller.close();

  Future<void> _commit() async {
    _sort();
    await _write();
    _emit();
  }

  Future<void> _write() async {
    try {
      await RecordLists.current.save(key, _items.map(toJson).toList());
      SaveHealth.saved(key);
    } catch (_) {
      // The user is told and can try again (SaveHealth).
      SaveHealth.failed(key, _write);
    }
  }

  void _sort() {
    if (compare != null) _items.sort(compare);
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }
}
