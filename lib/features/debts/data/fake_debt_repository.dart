import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/save_health.dart';
import 'package:smartbudget/core/storage/stored_list.dart';

import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_repository.dart';

/// Per-user device-local debts store for development (Supabase replaces it later
/// behind the same interface).
class FakeDebtRepository implements DebtRepository {
  FakeDebtRepository({required this.userId}) {
    _controller = StreamController<List<Debt>>.broadcast(onListen: _emitInitial);
  }

  final String userId;
  late final StreamController<List<Debt>> _controller;
  final List<Debt> _items = <Debt>[];
  bool _loaded = false;

  String get _key => 'sb_debts_$userId';

  @override
  List<Debt> get current => List<Debt>.unmodifiable(_items);

  @override
  Stream<List<Debt>> watchAll() => _controller.stream;

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
        // Unreadable entries are skipped, never the whole list.
        _items
          ..clear()
          ..addAll(StoredList.read(prefs, _key, raw, Debt.fromJson));
        _sort();
      }
    } catch (_) {
      // Start empty.
    }
  }

  @override
  Future<void> add(Debt debt) async {
    await _load();
    _items.add(debt);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<void> update(Debt debt) async {
    await _load();
    final int i = _items.indexWhere((Debt d) => d.id == debt.id);
    if (i != -1) {
      _items[i] = debt;
      _sort();
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((Debt d) => d.id == id);
    await _persist();
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<void> replaceAll(List<Debt> items) async {
    await _load();
    _items
      ..clear()
      ..addAll(items);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<int> importMany(List<Debt> debts) async {
    await _load();
    final Set<String> existing = _items.map((Debt x) => x.id).toSet();
    int added = 0;
    for (final Debt d in debts) {
      if (d.id.isEmpty || existing.contains(d.id)) continue;
      _items.add(d);
      existing.add(d.id);
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
    _items.sort((Debt a, Debt b) => b.createdAt.compareTo(a.createdAt));
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool ok = await prefs.setString(
        _key,
        jsonEncode(_items.map((Debt d) => d.toJson()).toList()),
      );
      if (!ok) throw StateError('not stored');
      SaveHealth.saved(_key);
    } catch (_) {
      // The user is told and can try again (SaveHealth).
      SaveHealth.failed(_key, _persist);
    }
  }
}
