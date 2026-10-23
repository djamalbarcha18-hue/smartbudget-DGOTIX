import 'dart:typed_data';

import 'package:smartbudget/features/share/data/native_share.dart';

/// The browser's share sheet; nothing is written to disk on the web.
Future<bool> shareTripImage(Uint8List png,
    {required String text, required String filename}) async {
  final NativeShareResult r =
      await shareNatively(text: text, pngBytes: png, filename: filename);
  return r != NativeShareResult.unsupported;
}

Future<void> cleanUpTripImages() async {}
