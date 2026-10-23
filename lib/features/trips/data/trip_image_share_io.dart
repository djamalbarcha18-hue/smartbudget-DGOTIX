import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'package:smartbudget/features/trips/data/trip_image_share.dart'
    show TripShareOutcome;

/// Shares [png] with [text] through the system share sheet. The image goes
/// through a temporary file of its own, removed by [cleanUpTripImages] once
/// the receiving app has had time to read it (when the preview closes, and
/// before the next share).
Future<TripShareOutcome> shareTripImage(Uint8List png,
    {required String text, required String filename}) async {
  await cleanUpTripImages();
  try {
    final Directory dir = await _dir().create(recursive: true);
    final File file = File('${dir.path}/$filename');
    await file.writeAsBytes(png, flush: true);
    final ShareResult r = await SharePlus.instance.share(ShareParams(
      text: text,
      files: <XFile>[XFile(file.path, mimeType: 'image/png')],
    ));
    return r.status == ShareResultStatus.dismissed
        ? TripShareOutcome.cancelled
        : TripShareOutcome.shared;
  } catch (_) {
    return TripShareOutcome.failed;
  }
}

/// Removes the temporary images made by [shareTripImage].
Future<void> cleanUpTripImages() async {
  try {
    final Directory dir = _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {
    // Nothing to remove, or the system already cleared its cache.
  }
}

Directory _dir() => Directory('${Directory.systemTemp.path}/smarttrip_share');
