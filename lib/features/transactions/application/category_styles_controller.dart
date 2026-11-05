import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/storage/save_health.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The icon and colour family a user picked for a category they made.
/// Kept beside (not inside) the category list so sync and backup of the
/// names stay untouched; a missing entry just shows the neutral tag.
class CustomCategoryLook {
  const CustomCategoryLook(this.iconKey, this.familyName);
  final String iconKey;
  final String familyName;
  String get encoded => '$iconKey|$familyName';

  static CustomCategoryLook? decode(Object? v) {
    if (v is! String) return null;
    final List<String> p = v.split('|');
    return p.length == 2 && p[0].isNotEmpty && p[1].isNotEmpty
        ? CustomCategoryLook(p[0], p[1])
        : null;
  }
}

String categoryLookKey(TransactionType t, String name) =>
    '${t == TransactionType.income ? 'i' : 'e'}:$name';

final categoryStylesProvider =
    NotifierProvider<CategoryStylesController, Map<String, CustomCategoryLook>>(
        CategoryStylesController.new);

class CategoryStylesController
    extends Notifier<Map<String, CustomCategoryLook>> {
  static const String _base = 'sb_category_styles';
  String _key = '';

  @override
  Map<String, CustomCategoryLook> build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _key = AccountKeys.of(_base, account);
    _load(account);
    return const <String, CustomCategoryLook>{};
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (await AccountKeys.open(p, _base, account) != _key) return;
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, CustomCategoryLook> out =
          <String, CustomCategoryLook>{};
      m.forEach((String k, dynamic v) {
        final CustomCategoryLook? look = CustomCategoryLook.decode(v);
        if (look != null) out[k] = look;
      });
      state = out;
    } catch (_) {
      // Keep the neutral tags.
    }
  }

  Future<void> set(TransactionType type, String name, CustomCategoryLook look) {
    state = <String, CustomCategoryLook>{
      ...state,
      categoryLookKey(type, name): look,
    };
    return _save();
  }

  Future<void> remove(TransactionType type, String name) {
    state = <String, CustomCategoryLook>{...state}
      ..remove(categoryLookKey(type, name));
    return _save();
  }

  Future<void> _save() => _write(
      _key,
      jsonEncode(<String, String>{
        for (final MapEntry<String, CustomCategoryLook> e in state.entries)
          e.key: e.value.encoded,
      }));

  static Future<void> _write(String key, String raw) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (!await p.setString(key, raw)) throw StateError('not stored');
      SaveHealth.saved(key);
    } catch (_) {
      SaveHealth.failed(key, () => _write(key, raw));
    }
  }
}
