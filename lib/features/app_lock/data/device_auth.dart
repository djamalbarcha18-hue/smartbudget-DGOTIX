/// Unlocking with the device's own lock (fingerprint, face, Windows Hello)
/// through WebAuthn platform authenticators. The web implementation lives in
/// [device_auth_web.dart]; elsewhere it reports unavailable.
library;

export 'device_auth_stub.dart' if (dart.library.js_interop) 'device_auth_web.dart';
