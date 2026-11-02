/// Asks the browser to keep this site's storage (where the app saves the
/// user's financial data) instead of evicting it when the device runs low on
/// space. Web-only; a no-op elsewhere (e.g. the Dart VM used by tests).
library;

export 'persistent_storage_stub.dart'
    if (dart.library.js_interop) 'persistent_storage_web.dart';
