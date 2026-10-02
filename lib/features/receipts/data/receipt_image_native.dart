/// Receipt photo cleanup with the platform's own image engine.
///
/// On the web ([receipt_image_native_web.dart]) the browser decodes, crops,
/// grays and re-encodes the photo natively (milliseconds; decoding in Dart
/// there takes seconds and blocks the screen). Elsewhere the stub returns
/// null and the caller uses [ReceiptImagePrep] in a background isolate.
library;

export 'receipt_image_native_stub.dart'
    if (dart.library.html) 'receipt_image_native_web.dart';
