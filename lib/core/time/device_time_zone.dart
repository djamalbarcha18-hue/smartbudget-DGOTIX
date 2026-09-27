/// The device's IANA time zone name (e.g. `Africa/Algiers`), when the platform
/// can tell. The web implementation asks the browser's Intl API.
library;

export 'device_time_zone_stub.dart'
    if (dart.library.js_interop) 'device_time_zone_web.dart';
