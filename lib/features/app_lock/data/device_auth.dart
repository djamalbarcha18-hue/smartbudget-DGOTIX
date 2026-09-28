/// Unlocking with the device's own lock (fingerprint, face, Windows Hello):
/// WebAuthn platform authenticators on the web ([device_auth_web.dart]),
/// local_auth on Android/iOS ([device_auth_io.dart]).
library;

export 'device_auth_stub.dart'
    if (dart.library.js_interop) 'device_auth_web.dart'
    if (dart.library.io) 'device_auth_io.dart';
