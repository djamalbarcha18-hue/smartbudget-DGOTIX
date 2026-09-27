import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/install/data/pwa_install.dart';

/// What can be offered right now; updates when the browser makes the app
/// installable or it gets installed.
final installModeProvider = StreamProvider<InstallMode>((ref) async* {
  yield installMode();
  await for (final void _ in installChanges()) {
    yield installMode();
  }
});

/// Whether the dashboard banner was dismissed recently (it comes back after
/// [InstallBannerController.snooze]).
final installBannerProvider =
    NotifierProvider<InstallBannerController, bool>(InstallBannerController.new);

class InstallBannerController extends Notifier<bool> {
  static const String _key = 'sb_install_dismissed_at';
  static const Duration snooze = Duration(days: 30);

  @override
  bool build() {
    _load();
    return true; // hidden until we know
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final DateTime? at = DateTime.tryParse(p.getString(_key) ?? '');
      state = at != null && AppClock.now().difference(at) < snooze;
    } catch (_) {
      state = false;
    }
  }

  Future<void> dismiss() async {
    state = true;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, AppClock.now().toIso8601String());
    } catch (_) {
      // Non-fatal.
    }
  }
}
