/// Asks the browser to keep this site's storage (where the app saves the
/// user's financial data) instead of evicting it when the device runs low on
/// space. Web-only; a no-op elsewhere (e.g. the Dart VM used by tests).
export 'persistent_storage_stub.dart'
    if (dart.library.html) 'persistent_storage_web.dart';
