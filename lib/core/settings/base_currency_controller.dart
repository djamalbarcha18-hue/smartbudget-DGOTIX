import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/currency.dart';

/// The user's single base/display currency.
///
/// Totals and reports are in this currency; a transaction in another currency
/// counts through the base value recorded with it (`Transaction.baseAmount`).
/// Persisted on the device and synced.
final baseCurrencyProvider =
    NotifierProvider<BaseCurrencyController, String>(BaseCurrencyController.new);

/// True once the saved base currency has been read. Until then
/// [baseCurrencyProvider] holds the USD default, so anything that writes
/// values in the base currency waits for this.
final baseCurrencyLoadedProvider = StateProvider<bool>((ref) => false);

class BaseCurrencyController extends Notifier<String> {
  static const String _key = 'sb_base_currency';

  @override
  String build() {
    _load();
    return Currencies.usd.code;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_key);
      if (code != null && code.isNotEmpty) state = code;
    } catch (_) {
      // Keep default.
    }
    try {
      ref.read(baseCurrencyLoadedProvider.notifier).state = true;
    } catch (_) {
      // Disposed before the read finished: nothing left to tell.
    }
  }

  Future<void> set(String code) async {
    state = code;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {
      // Non-fatal.
    }
  }
}
