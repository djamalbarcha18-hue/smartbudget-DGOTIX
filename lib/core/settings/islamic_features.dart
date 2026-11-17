import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';

/// "Show Islamic features": one display preference for the whole app (zakat,
/// the Ramadan and Eid seasons, the Sadaqah Planner's wording). It is a
/// choice of what to show, never a question about the user's religion.
///
/// Off, those features leave the menu and the screens, and the Sadaqah
/// Planner becomes a neutral Giving Planner; nothing is deleted, and turning
/// it back on shows everything as it was. Kept on this device, like the
/// language.
abstract final class IslamicFeatures {
  static const String _key = 'sb_islamic_features';

  /// Languages whose speakers get "on" as the suggested answer. The user
  /// decides either way (many Muslims in Europe use French or English).
  static const Set<String> _onByDefault = <String>{
    'ar',
    'ur',
    'id',
    'ms',
    'tr',
    'fa',
  };

  /// Whether the features are shown. Changes take effect at once.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Whether the user has answered (in the dashboard card or in Settings).
  static final ValueNotifier<bool> chosen = ValueNotifier<bool>(false);

  static bool suggestedFor(String languageCode) =>
      _onByDefault.contains(languageCode);

  /// Read once at start, before the first frame.
  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? saved = prefs.getBool(_key);
      final String lang = AppLang.tryCode(prefs.getString('sb_locale'))?.code ??
          AppLang.tryCode(PlatformDispatcher.instance.locale.languageCode)
              ?.code ??
          AppLang.ar.code;
      chosen.value = saved != null;
      enabled.value = saved ?? suggestedFor(lang);
    } catch (_) {
      // Keep the defaults.
    }
  }

  static int _writes = 0;

  /// Shows or hides the features. The screens follow at once; the choice is
  /// saved right after, and only the last of several quick taps is kept.
  static Future<void> set(bool on) async {
    chosen.value = true;
    enabled.value = on;
    final int write = ++_writes;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (write != _writes) return;
      await prefs.setBool(_key, on);
    } catch (_) {
      // Non-fatal: the screens already follow the choice.
    }
  }
}

/// [IslamicFeatures.enabled] for providers that depend on it.
final islamicFeaturesProvider = Provider<bool>((ref) {
  void changed() => ref.invalidateSelf();
  IslamicFeatures.enabled.addListener(changed);
  ref.onDispose(() => IslamicFeatures.enabled.removeListener(changed));
  return IslamicFeatures.enabled.value;
});
