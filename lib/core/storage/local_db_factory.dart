/// The device database's engine: IndexedDB in the browser; on Android a
/// database file in the app's own storage (kept by «clear cache», removed by
/// «clear data» or uninstalling); none elsewhere (tests, desktop).
library;

export 'local_db_factory_io.dart'
    if (dart.library.js_interop) 'local_db_factory_web.dart';
