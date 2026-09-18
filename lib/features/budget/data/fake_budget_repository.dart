import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/budget/domain/budget_repository.dart';

/// Per-user device-local budget-targets store for development.
class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository({required this.userId}) {
    _controller =
        StreamController<List<BudgetTarget>>.broadcast(onListen: _emitInitial);
  }

  final String userId;
  late final StreamController<List<BudgetTarget>> _controller;
  final List<BudgetTarget> _items = <BudgetTarget>[];
  bool _loaded = false;

  String get _key => 'sb_budgets_$userId';

  @override
  List<BudgetTarget> get current => List<BudgetTarget>.unmodifiable(_items);

  @override
  Stream<List<BudgetTarget>> watchAll() => _controller.stream;

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
          ..addAll(list.map(
              (dynamic e) => BudgetTarget.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // Start empty.
    }
  }

  @override
  Future<void> setPlanned({
    required int year,
    required int month,
    required String category,
    required double amount,
    required String currencyCode,
  }) async {
    await _load();
    final int i = _items.indexWhere((BudgetTarget b) =>
        b.year == year && b.month == month && b.category == category);
    if (amount <= 0) {
      if (i != -1) _items.removeAt(i);
    } else {
      final Money planned = Money.fromDouble(amount, currencyCode);
      if (i != -1) {
        final BudgetTarget prev = _items[i];
        _items[i] = BudgetTarget(
          id: prev.id,
          year: year,
          month: month,
          category: category,
          planned: planned,
          createdAt: prev.createdAt,
        );
      } else {
        _items.add(BudgetTarget(
          id: 'bud-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
          year: year,
          month: month,
          category: category,
          planned: planned,
          createdAt: DateTime.now(),
        ));
      }
    }
    await _persist();
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((BudgetTarget b) => b.id == id);
    await _persist();
    _emit();
  }

  @override
  Future<int> importMany(List<BudgetTarget> targets) async {
    await _load();
    bool collides(BudgetTarget t) => _items.any((BudgetTarget e) =>
        e.year == t.year && e.month == t.month && e.category == t.category);
    int added = 0;
    for (final BudgetTarget t in targets) {
      if (collides(t)) continue;
      _items.add(t);
      added++;
    }
    if (added > 0) {
      await _persist();
      _emit();
    }
    return added;
  }

  @override
  Future<int> deleteMany(Iterable<String> ids) async {
    await _load();
    final Set<String> set = ids.toSet();
    final int before = _items.length;
    _items.removeWhere((BudgetTarget b) => set.contains(b.id));
    final int removed = before - _items.length;
    if (removed > 0) {
      await _persist();
      _emit();
    }
    return removed;
  }

  @override
  void dispose() {
    _controller.close();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_items.map((BudgetTarget b) => b.toJson()).toList()),
      );
    } catch (_) {
      // Non-fatal for dev.
    }
  }
}
