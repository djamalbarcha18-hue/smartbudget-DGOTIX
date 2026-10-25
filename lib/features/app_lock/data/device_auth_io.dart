import 'dart:ui' show PlatformDispatcher;

import 'package:local_auth/local_auth.dart';

import 'package:smartbudget/core/app_restart.dart';

/// Mobile: the phone's own lock (fingerprint, face or device PIN) through
/// local_auth. There is no credential to keep, so a fixed marker is stored.
const String _marker = 'device';

final LocalAuthentication _auth = LocalAuthentication();

String get _reason => switch (PlatformDispatcher.instance.locale.languageCode) {
      'ar' => 'افتح SmartBudget',
      'fr' => 'Déverrouiller SmartBudget',
      'id' => 'Buka SmartBudget',
      'es' => 'Desbloquear SmartBudget',
      'tr' => 'SmartBudget kilidini aç',
      'ms' => 'Buka kunci SmartBudget',
      'ur' => 'SmartBudget کھولیں',
      'de' => 'SmartBudget entsperren',
      'pt' => 'Desbloquear o SmartBudget',
      'it' => 'Sblocca SmartBudget',
      'nl' => 'SmartBudget ontgrendelen',
      'bs' => 'Otključaj SmartBudget',
      'sq' => 'Zhblloko SmartBudget',
      'ru' => 'Разблокировать SmartBudget',
      'sw' => 'Fungua SmartBudget',
      'ha' => 'Buɗe SmartBudget',
      'af' => 'Ontsluit SmartBudget',
      'fa' => 'باز کردن SmartBudget',
      'hi' => 'SmartBudget अनलॉक करें',
      _ => 'Unlock SmartBudget',
    };

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
