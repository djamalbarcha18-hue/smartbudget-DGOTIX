import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/currency.dart';

/// The user's single base/display currency.
///
/// P3 keeps ONE currency per user (no cross-currency mixing) because summing
/// different currencies requires conversion via exchange rates — a later phase.
/// This is a display/settings preference, persisted per viewer.
final baseCurrencyProvider =
    NotifierProvider<BaseCurrencyController, String>(BaseCurrencyController.new);

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
