import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// User-defined income/expense categories (on top of the built-in [Catalog]).
class CustomCategories {
  const CustomCategories({this.income = const <String>[], this.expense = const <String>[]});
  final List<String> income;
  final List<String> expense;

  List<String> forType(TransactionType t) =>
      t == TransactionType.income ? income : expense;
}

final customCategoriesProvider =
    NotifierProvider<CustomCategoriesController, CustomCategories>(
        CustomCategoriesController.new);

class CustomCategoriesController extends Notifier<CustomCategories> {
  static const String _key = 'sb_custom_categories';

  @override
  CustomCategories build() {
    _load();
    return const CustomCategories();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
        state = CustomCategories(
          income: _asList(m['income']),
          expense: _asList(m['expense']),
        );
      }
    } catch (_) {
      // Keep empty.
    }
  }

  static List<String> _asList(Object? v) =>
      v is List ? v.whereType<String>().toList() : const <String>[];

  Future<void> _save() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode(<String, dynamic>{
            'income': state.income,
            'expense': state.expense,
          }));
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> add(TransactionType type, String name) {
    final String n = name.trim();
    if (n.isEmpty) return Future<void>.value();
    final List<String> current = state.forType(type);
    // Skip duplicates and names that collide with a built-in category.
    if (current.contains(n) || Catalog.categoriesFor(type).contains(n)) {
      return Future<void>.value();
    }
    _set(type, <String>[...current, n]);
    return _save();
  }

  Future<void> remove(TransactionType type, String name) {
    _set(type, state.forType(type).where((String c) => c != name).toList());
    return _save();
  }

  /// Merge-imports custom categories (used by backup restore). Skips names that
  /// duplicate an existing custom entry or a built-in [Catalog] category.
  Future<void> importMany({
    List<String> income = const <String>[],
    List<String> expense = const <String>[],
  }) {
    final List<String> incomeNext =
        _merged(state.income, income, TransactionType.income);
    final List<String> expenseNext =
        _merged(state.expense, expense, TransactionType.expense);
    state = CustomCategories(income: incomeNext, expense: expenseNext);
    return _save();
  }

  static List<String> _merged(
      List<String> current, List<String> incoming, TransactionType type) {
    final List<String> out = <String>[...current];
    final List<String> builtIn = Catalog.categoriesFor(type);
    for (final String raw in incoming) {
      final String n = raw.trim();
      if (n.isEmpty || out.contains(n) || builtIn.contains(n)) continue;
      out.add(n);
    }
    return out;
  }

  void _set(TransactionType type, List<String> next) {
    state = type == TransactionType.income
        ? CustomCategories(income: next, expense: state.expense)
        : CustomCategories(income: state.income, expense: next);
  }
}

/// Effective categories for a type: built-in defaults + custom, with the
/// 'أخرى' (Other) bucket always kept last.
final categoriesForProvider =
    Provider.family<List<String>, TransactionType>((ref, TransactionType type) {
  final List<String> custom = ref.watch(customCategoriesProvider).forType(type);
  final List<String> defaults = Catalog.categoriesFor(type);
  const String other = 'أخرى';
  return <String>[
    ...defaults.where((String c) => c != other),
    ...custom.where((String c) => c != other && !defaults.contains(c)),
    other,
  ];
});
