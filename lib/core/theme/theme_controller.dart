import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the active [ThemeMode] and persists it per viewer.
///
/// Dark mode is the default (primary premium experience). The choice is stored
/// in shared_preferences — a per-viewer convenience, never financial data — and
/// every read/write is guarded so a storage failure can never break the app.
/// The calm look for the light theme (experimental; see AppEnv.calmTheme).
final calmThemeProvider =
    NotifierProvider<CalmThemeController, bool>(CalmThemeController.new);

class CalmThemeController extends Notifier<bool> {
  static const String _key = 'sb_theme_calm';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, on);
    } catch (_) {
      // Non-fatal.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const String _key = 'sb_theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null) state = _parse(raw);
    } catch (_) {
      // Ignore — keep the default. Storage is optional.
    }
  }

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Non-fatal.
    }
  }

  ThemeMode _parse(String raw) => switch (raw) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}
