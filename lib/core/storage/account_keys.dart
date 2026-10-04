import 'package:shared_preferences/shared_preferences.dart';

/// Keys for data that belongs to one account, so another account signed in on
/// the same device never sees it.
///
/// Earlier versions kept some of this data under a single key for the whole
/// device. The first signed-in account to open it after the update takes it
/// over, and the shared copy is removed.
abstract final class AccountKeys {
  /// Personal data older versions kept for the whole device (see [open]).
  static const List<String> sharedByOlderVersions = <String>[
    'sb_ai_chat',
    'sb_ai_usage',
    'sb_backup_snooze',
    'sb_custom_categories',
    'sb_emergency_savings',
    'sb_last_backup',
    'sb_portfolio_capacity',
    'sb_zakat_inputs',
  ];

  /// The account [key] holds data for, or null for a device-wide key.
  static String? ownerOf(String key) => _owned.firstMatch(key)?.group(1);

  // `sb_<name>_<account id>`: a server account (UUID), or an account from
  // before real accounts (`dev-<number>`).
  static final RegExp _owned = RegExp(
      r'^sb_.+_([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
      r'|dev--?\d+)$');

  /// The key for [base] of the account [userId] (`guest` when signed out).
  static String of(String base, String? userId) =>
      '${base}_${userId ?? 'guest'}';

  /// [of], after moving a device-wide value of [base] to a signed-in account.
  static Future<String> open(
    SharedPreferences prefs,
    String base,
    String? userId,
  ) async {
    final String key = of(base, userId);
    if (userId != null && prefs.containsKey(base)) {
      if (prefs.containsKey(key)) {
        await prefs.remove(base);
      } else {
        await movePref(prefs, base, key);
      }
    }
    return key;
  }
}

/// Moves the value stored under [from] (of any type) to [to].
Future<void> movePref(SharedPreferences prefs, String from, String to) async {
  final Object? value = prefs.get(from);
  switch (value) {
    case String v:
      await prefs.setString(to, v);
    case bool v:
      await prefs.setBool(to, v);
    case int v:
      await prefs.setInt(to, v);
    case double v:
      await prefs.setDouble(to, v);
    case List<String> v:
      await prefs.setStringList(to, v);
  }
  await prefs.remove(from);
}
