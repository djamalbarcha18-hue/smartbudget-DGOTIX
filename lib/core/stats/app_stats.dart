import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/core/env/app_env.dart';

/// What the app counts (supabase/app_stats.sql knows the same names).
enum StatEvent {
  tripCreated('trip_created');

  const StatEvent(this.id);
  final String id;
}

/// Sends an event's name to the server, which adds one to that day's total.
typedef StatSender = Future<void> Function(String event);

/// The real sender: none while the totals are off (AppEnv.anonStats), without
/// a backend, or in debug builds, so testing never adds to the totals.
final statSenderProvider = Provider<StatSender>((ref) {
  if (!AppEnv.anonStats || !AppEnv.hasSupabase || kDebugMode) {
    return (_) async {};
  }
  return (String event) => Supabase.instance.client
      .rpc<void>('count_event', params: <String, dynamic>{'event_name': event});
});

/// Whether the user lets the app add to the anonymous totals (on unless
/// turned off in Settings).
final appStatsOnProvider =
    NotifierProvider<AppStatsOnController, bool>(AppStatsOnController.new);

class AppStatsOnController extends Notifier<bool> {
  static const String key = 'sb_anon_stats';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final bool? v = (await SharedPreferences.getInstance()).getBool(key);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(key, on);
    } catch (_) {}
  }
}

final appStatsProvider = Provider<AppStats>(AppStats.new);

/// Anonymous daily totals, such as how many trips were planned each day, so
/// there are real numbers to show partners. Only the event's name is sent:
/// no account, device, trip, place or amount. Offline, the count is skipped
/// (the totals are a guide, not an audit).
class AppStats {
  AppStats(this._ref);
  final Ref _ref;

  Future<void> count(StatEvent event) async {
    try {
      final bool? on = (await SharedPreferences.getInstance())
          .getBool(AppStatsOnController.key);
      if (on == false) return;
      await _ref.read(statSenderProvider)(event.id);
    } catch (_) {
      // Never in the user's way.
    }
  }
}
