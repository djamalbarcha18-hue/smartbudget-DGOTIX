import 'dart:async';

import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/save_health.dart';

import 'package:smartbudget/features/recurring/domain/recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';

/// Per-user device-local store of recurring rules.
class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository({required this.userId}) {
    _controller = StreamController<List<RecurringRule>>.broadcast(
      onListen: _emitInitial,
    );
  }

  final String userId;
  late final StreamController<List<RecurringRule>> _controller;
  final List<RecurringRule> _items = <RecurringRule>[];
  Future<void>? _loading;

  String get _key => 'sb_recurring_$userId';

  @override
  List<RecurringRule> get current => List<RecurringRule>.unmodifiable(_items);

  @override
  Stream<List<RecurringRule>> watchAll() => _controller.stream;

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
      final List<RecurringRule> stored =
          await RecordLists.current.load(_key, RecurringRule.fromJson);
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

  @override
  Future<void> add(RecurringRule rule) async {
    await _load();
    _items.add(rule);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<void> update(RecurringRule rule) => updateMany(<RecurringRule>[rule]);

  @override
  Future<void> updateMany(List<RecurringRule> rules) async {
    await _load();
    bool changed = false;
    for (final RecurringRule r in rules) {
      final int i = _items.indexWhere((RecurringRule x) => x.id == r.id);
      if (i != -1) {
        _items[i] = r;
        changed = true;
      }
    }
    if (changed) {
      _sort();
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((RecurringRule r) => r.id == id);
    await _persist();
    _emit();
  }

  @override
  Future<void> replaceAll(List<RecurringRule> items) async {
    await _load();
    _items
      ..clear()
      ..addAll(items);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<int> importMany(List<RecurringRule> rules) async {
    await _load();
    final Set<String> existing = _items.map((RecurringRule r) => r.id).toSet();
    int added = 0;
    for (final RecurringRule r in rules) {
      if (r.id.isEmpty || existing.contains(r.id)) continue;
      _items.add(r);
      existing.add(r.id);
      added++;
    }
    if (added > 0) {
      _sort();
      await _persist();
      _emit();
    }
    return added;
  }

  @override
  void dispose() {
    _controller.close();
  }

  void _sort() {
    _items.sort(
        (RecurringRule a, RecurringRule b) => a.createdAt.compareTo(b.createdAt));
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      await RecordLists.current.save(
          _key, _items.map((RecurringRule r) => r.toJson()).toList());
      SaveHealth.saved(_key);
    } catch (_) {
      // The user is told and can try again (SaveHealth).
      SaveHealth.failed(_key, _persist);
    }
  }
}
