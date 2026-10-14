import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/currency_defaults.dart';
import 'package:smartbudget/core/storage/account_keys.dart';

/// The user's single base/display currency.
///
/// Totals and reports are in this currency; a transaction in another currency
/// counts through the base value recorded with it (`Transaction.baseAmount`).
/// Persisted on the device and synced.
///
/// Until the user chooses one (or records a first transaction), it is only a
/// suggestion that follows the app language and the device region
/// ([CurrencyDefaults]): it isn't saved or synced, so signing in on a new
/// device takes the account's own currency.
final baseCurrencyProvider =
    NotifierProvider<BaseCurrencyController, String>(BaseCurrencyController.new);

/// True once the saved base currency has been read. Until then
/// [baseCurrencyProvider] holds the USD default, so anything that writes
/// values in the base currency waits for this.
final baseCurrencyLoadedProvider = StateProvider<bool>((ref) => false);

class BaseCurrencyController extends Notifier<String> {
  static const String _key = 'sb_base_currency';

  bool _chosen = false;

  /// False while the currency is only the suggestion for the language.
  bool get isChosen => _chosen;

  @override
  String build() {
    _load();
    return Currencies.usd.code;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_key);
      if (code != null && code.isNotEmpty) {
        _chosen = true;
        state = code;
      } else if (_usedBefore(prefs)) {
        // Data from versions that defaulted to the dollar without saving it:
        // keep the dollar so those records stay in the totals.
        await set(Currencies.usd.code);
      } else {
        final String? saved = prefs.getString('sb_locale');
        state = _suggestion(AppLang.fromCode(
            saved ?? PlatformDispatcher.instance.locale.languageCode));
      }
    } catch (_) {
      // Keep default.
    }
    try {
      ref.read(baseCurrencyLoadedProvider.notifier).state = true;
    } catch (_) {
      // Disposed before the read finished: nothing left to tell.
    }
  }

  static bool _usedBefore(SharedPreferences prefs) => prefs.getKeys().any(
      (String k) => k.startsWith('sb_txns_') || AccountKeys.ownerOf(k) != null);

  static String _suggestion(AppLang lang) {
    final Locale device = PlatformDispatcher.instance.locale;
    return CurrencyDefaults.suggest(lang,
        country: device.countryCode, deviceLanguage: device.languageCode);
  }

  /// Moves the suggestion to [lang]'s currency, unless the user chose one.
  void followLanguage(AppLang lang) {
    if (!_chosen) state = _suggestion(lang);
  }

  /// Keeps the current suggestion for good (the first transaction is
  /// recorded in it).
  Future<void> keep() async {
    if (!_chosen) await set(state);
  }

  Future<void> set(String code) async {
    _chosen = true;
    state = code;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {
      // Non-fatal.
    }
  }
}
