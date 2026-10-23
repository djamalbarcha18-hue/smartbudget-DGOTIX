import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the active [ThemeMode] and persists it per viewer.
///
/// Dark mode is the default (primary premium experience). The choice is stored
/// in shared_preferences — a per-viewer convenience, never financial data — and
/// every read/write is guarded so a storage failure can never break the app.
/// The colours of the light theme: Classic (free) or a Pro theme.
enum AppThemeStyle { classic, beige, sage }

/// The chosen light-theme colours (see AppEnv.proThemes). Stored on the
/// device only.
final themeStyleProvider =
    NotifierProvider<ThemeStyleController, AppThemeStyle>(
        ThemeStyleController.new);

class ThemeStyleController extends Notifier<AppThemeStyle> {
  static const String _key = 'sb_theme_style';

  /// The earlier on/off setting for beige.
  static const String _oldKey = 'sb_theme_calm';

  @override
  AppThemeStyle build() {
    _load();
    return AppThemeStyle.classic;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString(_key);
      if (name != null) {
        state = AppThemeStyle.values.firstWhere(
            (AppThemeStyle s) => s.name == name,
            orElse: () => AppThemeStyle.classic);
      } else if (prefs.getBool(_oldKey) ?? false) {
        state = AppThemeStyle.beige;
      }
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> set(AppThemeStyle style) async {
    state = style;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, style.name);
      await prefs.remove(_oldKey);
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
