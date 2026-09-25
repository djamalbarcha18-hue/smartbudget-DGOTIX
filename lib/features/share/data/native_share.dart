/// The system share sheet (Web Share API) — lets the user pick any installed
/// app, including ones with no web share link (Instagram, Snapchat…).
///
/// The web implementation lives in [native_share_web.dart]; the stub keeps the
/// Dart VM (test runner) compiling.
library;

export 'native_share_stub.dart' if (dart.library.html) 'native_share_web.dart';
