import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/data/fake_auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';

/// Before real accounts, the app signed people in on the device only, with the
/// id `FakeAuthRepository.idFor(email)`, and saved their data under keys
/// ending in `_<that id>`. When the same e-mail address first signs in to a
/// real account on this device, that data is moved to the account's id so
/// nothing looks lost. Data the account already has is never overwritten.
/// True when this device holds data saved by the device-only account of
/// [email], i.e. its owner used the app before real accounts and must create
/// the real account (same e-mail) rather than sign in.
bool hasDeviceOnlyData(SharedPreferences prefs, String email) {
  final String suffix = '_${FakeAuthRepository.idFor(email)}';
  return prefs
      .getKeys()
      .any((String k) => k.startsWith('sb_') && k.endsWith(suffix));
}

Future<void> adoptDeviceData(SharedPreferences prefs, AuthUser user) async {
  final String oldId = FakeAuthRepository.idFor(user.email);
  if (oldId == user.id) return;
  final String oldSuffix = '_$oldId';
  final List<String> keys = prefs
      .getKeys()
      .where((String k) => k.startsWith('sb_') && k.endsWith(oldSuffix))
      .toList();
  for (final String key in keys) {
    final String newKey =
        '${key.substring(0, key.length - oldId.length)}${user.id}';
    if (!prefs.containsKey(newKey)) {
      final Object? value = prefs.get(key);
      switch (value) {
        case String v:
          await prefs.setString(newKey, v);
        case bool v:
          await prefs.setBool(newKey, v);
        case int v:
          await prefs.setInt(newKey, v);
        case double v:
          await prefs.setDouble(newKey, v);
        case List<String> v:
          await prefs.setStringList(newKey, v);
        default:
          continue;
      }
    }
    await prefs.remove(key);
  }
}
