import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'package:smartbudget/features/share/data/native_share_stub.dart'
    show NativeShareResult;

export 'package:smartbudget/features/share/data/native_share_stub.dart'
    show NativeShareResult;

/// Mobile: the system share sheet always exists.
bool get canShareNatively => true;

/// Opens the Android/iOS share sheet with the text (the link appended when it
/// isn't already in it) and, with [pngBytes], the image attached.
Future<NativeShareResult> shareNatively({
  String? title,
  String? text,
  String? url,
  Uint8List? pngBytes,
  String? filename,
}) async {
  final String body = <String>[
    if (text != null && text.isNotEmpty) text,
    if (url != null && !(text ?? '').contains(url)) url,
  ].join('\n');
  final String name = filename ?? 'smartbudget.png';
  try {
    final ShareResult r = await SharePlus.instance.share(ShareParams(
      text: body.isEmpty ? null : body,
      title: title,
      subject: title,
      files: pngBytes == null
          ? null
          : <XFile>[
              XFile.fromData(pngBytes, mimeType: 'image/png', name: name)
            ],
      fileNameOverrides: pngBytes == null ? null : <String>[name],
    ));
    return r.status == ShareResultStatus.dismissed
        ? NativeShareResult.cancelled
        : NativeShareResult.shared;
  } catch (_) {
    return NativeShareResult.unsupported;
  }
}
