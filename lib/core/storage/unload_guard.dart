/// Asks the browser to warn before the page is closed or reloaded while
/// [pending] says some changes are not stored. Web only; a no-op elsewhere
/// (an app's memory is kept while it is in the background).
library;

export 'unload_guard_stub.dart'
    if (dart.library.js_interop) 'unload_guard_web.dart';
