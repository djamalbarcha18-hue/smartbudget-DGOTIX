import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';

/// Supported locales, from [AppLang] (Arabic first: the product is
/// Arabic-first).
abstract final class SupportedLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static final List<Locale> all = <Locale>[
    for (final AppLang l in AppLang.values) Locale(l.code),
  ];
}

/// Controls the active [Locale] and persists the choice per viewer.
///
/// Switching flips RTL/LTR automatically (via [Localizations]/[Directionality])
/// with no reload. Until one is chosen: the device language when the app
/// has it, else Arabic.
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
      final String device = PlatformDispatcher.instance.locale.languageCode;
      final AppLang? lang = AppLang.tryCode(code) ??
          (code == null ? AppLang.tryCode(device) : null);
      if (lang != null) state = Locale(lang.code);
    } catch (_) {
      // Keep default.
    }
  }

  /// Moves to the next supported locale (in [AppLang] order, back to the first).
  Future<void> toggle() {
    final int i = SupportedLocales.all
        .indexWhere((Locale l) => l.languageCode == state.languageCode);
    return set(SupportedLocales.all[(i + 1) % SupportedLocales.all.length]);
  }

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
