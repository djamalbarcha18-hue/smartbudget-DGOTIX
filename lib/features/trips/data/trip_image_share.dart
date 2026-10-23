/// Sharing the trip card image: a temporary file on Android/iOS (deleted
/// afterwards), the Web Share API on the web.
library;

export 'trip_image_share_web.dart'
    if (dart.library.io) 'trip_image_share_io.dart';

/// How a share ended.
enum TripShareOutcome {
  /// Sent to an app (or the system can't tell: counted as shared).
  shared,

  /// The user closed the share sheet without picking an app.
  cancelled,

  /// It couldn't be shared.
  failed,
}
