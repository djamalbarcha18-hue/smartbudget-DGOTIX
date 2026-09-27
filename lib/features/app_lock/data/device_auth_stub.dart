Future<bool> deviceAuthAvailable() async => false;

Future<String?> registerDeviceAuth({required String userName}) async => null;

Future<bool> verifyDeviceAuth(String credentialId) async => false;

/// Reloads the app from scratch (after erasing local data). No-op off the web.
void reloadApp() {}
