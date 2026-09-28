/// Platform file IO for backup export/import.
///
/// The web implementation ([file_io_web.dart]) uses browser download + file
/// picker APIs; on Android/iOS ([file_io_io.dart]) the system save dialog and
/// file picker. The stub ([file_io_stub.dart]) is a no-op elsewhere.
export 'file_io_stub.dart'
    if (dart.library.html) 'file_io_web.dart'
    if (dart.library.io) 'file_io_io.dart';
