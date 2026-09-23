import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  bool _loaded = false;

  String get _key => 'sb_recurring_$userId';

  @override
  List<RecurringRule> get current => List<RecurringRule>.unmodifiable(_items);

  @override
  Stream<List<RecurringRule>> watchAll() => _controller.stream;

  Future<void> _emitInitial() async {
    await _load();
    _emit();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(list.map((dynamic e) =>
              RecurringRule.fromJson(e as Map<String, dynamic>)));
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_items.map((RecurringRule r) => r.toJson()).toList()),
      );
    } catch (_) {
      // Non-fatal for dev.
    }
  }
}
