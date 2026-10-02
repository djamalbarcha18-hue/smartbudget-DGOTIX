/// Offline receipt reading: ML Kit on Android
/// ([offline_ocr_engine_io.dart]), unavailable on the web
/// ([offline_ocr_engine_stub.dart]).
library;

export 'offline_ocr_engine_stub.dart'
    if (dart.library.io) 'offline_ocr_engine_io.dart';
