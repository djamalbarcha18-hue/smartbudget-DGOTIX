/// Sharing the trip card image: a temporary file on Android/iOS (deleted
/// afterwards), the Web Share API on the web.
library;

export 'trip_image_share_web.dart'
    if (dart.library.io) 'trip_image_share_io.dart';
