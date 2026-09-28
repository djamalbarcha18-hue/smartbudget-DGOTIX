/// The system share sheet (Web Share API) — lets the user pick any installed
/// app, including ones with no web share link (Instagram, Snapchat…).
///
/// Web Share API on the web ([native_share_web.dart]); share_plus on
/// Android/iOS ([native_share_io.dart]).
library;

export 'native_share_stub.dart'
    if (dart.library.html) 'native_share_web.dart'
    if (dart.library.io) 'native_share_io.dart';
