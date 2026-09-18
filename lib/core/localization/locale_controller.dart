import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales. Ordered ar-first (the product is Arabic-first); French is
/// intentionally easy to add later — append a [Locale] and an ARB file, nothing
/// else changes.
abstract final class SupportedLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static const List<Locale> all = <Locale>[arabic, english];
}

/// Controls the active [Locale] and persists the choice per viewer.
///
/// Switching flips RTL/LTR automatically (via [Localizations]/[Directionality])
/// with no reload. Default is Arabic.
final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  static const String _key = 'sb_locale';

  @override
  Locale build() {
    _load();
    return SupportedLocales.arabic;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_key);
      if (code != null) state = Locale(code);
    } catch (_) {
      // Keep default.
    }
  }

  /// Toggles between the first two supported locales (ar <-> en).
  Future<void> toggle() => set(
        state.languageCode == 'ar'
            ? SupportedLocales.english
            : SupportedLocales.arabic,
      );

  Future<void> set(Locale locale) async {
    state = locale;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {
      // Non-fatal.
    }
  }
}
