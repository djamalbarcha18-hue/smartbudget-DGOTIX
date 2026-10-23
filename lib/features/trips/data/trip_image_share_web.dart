import 'dart:typed_data';

import 'package:smartbudget/features/share/data/native_share.dart';
import 'package:smartbudget/features/trips/data/trip_image_share.dart'
    show TripShareOutcome;

/// The browser's share sheet; nothing is written to disk on the web.
Future<TripShareOutcome> shareTripImage(Uint8List png,
    {required String text, required String filename}) async {
  final NativeShareResult r =
      await shareNatively(text: text, pngBytes: png, filename: filename);
  return switch (r) {
    NativeShareResult.shared => TripShareOutcome.shared,
    NativeShareResult.cancelled => TripShareOutcome.cancelled,
    NativeShareResult.unsupported => TripShareOutcome.failed,
  };
}

Future<void> cleanUpTripImages() async {}
