/// The browser's IndexedDB, or null where there is none (the app on a
/// phone, tests).
library;

export 'local_db_factory_stub.dart'
    if (dart.library.js_interop) 'local_db_factory_web.dart';
