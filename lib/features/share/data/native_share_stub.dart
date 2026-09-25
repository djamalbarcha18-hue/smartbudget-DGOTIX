import 'dart:typed_data';

enum NativeShareResult { shared, cancelled, unsupported }

/// Whether the system share sheet exists here. Always false off the web.
bool get canShareNatively => false;

/// Opens the system share sheet. Always unsupported off the web.
Future<NativeShareResult> shareNatively({
  String? title,
  String? text,
  String? url,
  Uint8List? pngBytes,
  String? filename,
}) async =>
    NativeShareResult.unsupported;
