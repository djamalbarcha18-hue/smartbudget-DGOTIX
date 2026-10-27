import 'dart:async';

import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/save_health.dart';

import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/domain/transaction_repository.dart';

/// Device-local transactions store for DEVELOPMENT — persists per user via
/// shared_preferences so data survives reload and stays isolated between
/// accounts. The Supabase implementation replaces this behind the same
/// interface with no UI/business changes.
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({required this.userId}) {
    _controller = StreamController<List<Transaction>>.broadcast(
      onListen: _emitInitial,
    );
  }

  final String userId;

  late final StreamController<List<Transaction>> _controller;
  final List<Transaction> _items = <Transaction>[];
  Future<void>? _loading;

  String get _key => 'sb_txns_$userId';

  @override
  List<Transaction> get current => List<Transaction>.unmodifiable(_items);

  @override
  Stream<List<Transaction>> watchAll() => _controller.stream;

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
      final List<Transaction> stored =
          await RecordLists.current.load(_key, Transaction.fromJson);
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
  Future<void> add(Transaction txn) async {
    await _load();
    _items.add(txn);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<void> update(Transaction txn) async {
    await _load();
    final int i = _items.indexWhere((Transaction t) => t.id == txn.id);
    if (i != -1) {
      _items[i] = txn;
      _sort();
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> delete(String id) async {
    await _load();
    _items.removeWhere((Transaction t) => t.id == id);
    await _persist();
    _emit();
  }

  @override
  Future<void> replaceAll(List<Transaction> items) async {
    await _load();
    _items
      ..clear()
      ..addAll(items);
    _sort();
    await _persist();
    _emit();
  }

  @override
  Future<int> importMany(List<Transaction> txns) async {
    await _load();
    final Set<String> existing =
        _items.map((Transaction t) => t.id).toSet();
    int added = 0;
    for (final Transaction t in txns) {
      if (t.id.isEmpty || existing.contains(t.id)) continue;
      _items.add(t);
      existing.add(t.id);
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
  Future<int> deleteMany(Iterable<String> ids) async {
    await _load();
    final Set<String> set = ids.toSet();
    final int before = _items.length;
    _items.removeWhere((Transaction t) => set.contains(t.id));
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

  // ---- helpers ----

  void _sort() {
    _items.sort((Transaction a, Transaction b) {
      final int byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  Future<void> _persist() async {
    try {
      await RecordLists.current.save(
          _key, _items.map((Transaction t) => t.toJson()).toList());
      SaveHealth.saved(_key);
    } catch (_) {
      // The user is told and can try again (SaveHealth).
      SaveHealth.failed(_key, _persist);
    }
  }
}
