/// The little hint that the logo on a phone is the menu button.
///
/// For the first few launches, until the person has opened the menu once, the
/// mark pulses a few times and a small bubble says what it is. After the first
/// tap, or after a handful of launches, it is never shown again. Kept on the
/// device only (a per-viewer convenience), every read and write guarded so a
/// storage failure can never break the bar.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract final class MenuHint {
  static const String _tappedKey = 'sb_menu_hint_tapped';
  static const String _launchesKey = 'sb_menu_hint_launches';

  /// The hint is offered on this many launches at most.
  static const int maxLaunches = 5;

  /// Whether to show it, from what is kept.
  static bool shouldShow({required bool tapped, required int launches}) =>
      !tapped && launches <= maxLaunches;

  static bool _counted = false;

  /// Reads the state; counts this launch once per app start. Returns whether
  /// the hint should show now.
  static Future<bool> active() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final bool tapped = p.getBool(_tappedKey) ?? false;
      int launches = p.getInt(_launchesKey) ?? 0;
      if (!_counted) {
        _counted = true;
        launches += 1;
        await p.setInt(_launchesKey, launches);
      }
      return shouldShow(tapped: tapped, launches: launches);
    } catch (_) {
      return false;
    }
  }

  /// The person opened the menu: they know now.
  static Future<void> markTapped() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_tappedKey, true);
    } catch (_) {
      // Best effort.
    }
  }

  /// Forgets that this launch was counted (tests only).
  static void resetForTest() => _counted = false;
}
