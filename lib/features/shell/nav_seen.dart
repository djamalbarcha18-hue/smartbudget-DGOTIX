import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The menu's "new" items the user has already opened (their routes): the
/// badge goes once a feature has been seen.
final navSeenProvider =
    NotifierProvider<NavSeenController, Set<String>>(NavSeenController.new);

class NavSeenController extends Notifier<Set<String>> {
  static const String _key = 'sb_nav_seen';

  @override
  Set<String> build() {
    _load();
    return const <String>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String>? seen = p.getStringList(_key);
      if (seen != null) state = <String>{...state, ...seen};
    } catch (_) {
      // Storage unavailable: the badges simply stay.
    }
  }

  /// Opened [route]: its "new" badge won't show again.
  Future<void> markSeen(String route) async {
    if (state.contains(route)) return;
    state = <String>{...state, route};
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList(_key, state.toList());
    } catch (_) {}
  }
}
