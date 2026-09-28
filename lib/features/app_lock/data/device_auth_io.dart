import 'dart:ui' show PlatformDispatcher;

import 'package:local_auth/local_auth.dart';

import 'package:smartbudget/core/app_restart.dart';

/// Mobile: the phone's own lock (fingerprint, face or device PIN) through
/// local_auth. There is no credential to keep, so a fixed marker is stored.
const String _marker = 'device';

final LocalAuthentication _auth = LocalAuthentication();

String get _reason => PlatformDispatcher.instance.locale.languageCode == 'ar'
    ? 'افتح SmartBudget'
    : 'Unlock SmartBudget';

Future<bool> deviceAuthAvailable() async {
  try {
    return await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

Future<String?> registerDeviceAuth({required String userName}) async =>
    await _verify() ? _marker : null;

Future<bool> verifyDeviceAuth(String credentialId) => _verify();

Future<bool> _verify() async {
  try {
    return await _auth.authenticate(
      localizedReason: _reason,
      persistAcrossBackgrounding: true,
    );
  } catch (_) {
    return false;
  }
}

/// Starts the app again from scratch (after erasing local data).
void reloadApp() {
  AppRestart.run();
}
