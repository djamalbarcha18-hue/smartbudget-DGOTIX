import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_repository.dart';

/// Per-user device-local goals store for development.
class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository({required this.userId}) {
    _controller = StreamController<List<Goal>>.broadcast(onListen: _emitInitial);
  }

  final String userId;
  late final StreamController<List<Goal>> _controller;
  final List<Goal> _items = <Goal>[];
  bool _loaded = false;

  String get _key => 'sb_goals_$userId';

  @override
  List<Goal> get current => List<Goal>.unmodifiable(_items);

  @override
  Stream<List<Goal>> watchAll() => _controller.stream;

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
          ..addAll(
              list.map((dynamic e) => Goal.fromJson(e as Map<String, dynamic>)));
        _sort();
      }
    } catch (_) {
      // Start empty.
    }
  }

  @override
  Future<void> add(Goal goal) async {
    await _load();
    _items.add(goal);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<void> update(Goal goal) async {
    await _load();
    final int i = _items.indexWhere((Goal g) => g.id == goal.id);
    if (i != -1) {
      _items[i] = goal;
      _sort();
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((Goal g) => g.id == id);
    await _persist();
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }

  void _sort() {
    _items.sort((Goal a, Goal b) => a.createdAt.compareTo(b.createdAt));
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_items.map((Goal g) => g.toJson()).toList()),
      );
    } catch (_) {
      // Non-fatal for dev.
    }
  }
}
