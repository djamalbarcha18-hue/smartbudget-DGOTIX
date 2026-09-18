/// Platform file IO for backup export/import.
///
/// The web implementation ([file_io_web.dart]) uses browser download + file
/// picker APIs; the stub ([file_io_stub.dart]) is a no-op so non-web targets
/// (notably the Dart VM used by `flutter test`) still compile and run.
export 'file_io_stub.dart' if (dart.library.html) 'file_io_web.dart';
