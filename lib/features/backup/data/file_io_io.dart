import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Mobile (Android/iOS) backup file IO: the system "save as" dialog, so the
/// user picks where the file goes (Downloads, Drive…), and the system file
/// picker to restore it.

/// Saves [text] as a file the user places with the system save dialog.
Future<void> downloadText({
  required String filename,
  required String text,
  required String mime,
}) =>
    _save(filename, Uint8List.fromList(utf8.encode(text)), mime);

/// Saves binary [bytes] with the system save dialog.
Future<void> downloadBytes({
  required String filename,
  required List<int> bytes,
  required String mime,
}) =>
    _save(filename, Uint8List.fromList(bytes), mime);

Future<void> _save(String filename, Uint8List bytes, String mime) async {
  try {
    await FilePicker.saveFile(
      fileName: filename,
      bytes: bytes,
      mimeType: mime.split(';').first.trim(),
    );
  } catch (_) {
    // Cancelled or unavailable: nothing was written.
  }
}

/// Lets the user choose a file and returns its text (null when cancelled).
Future<String?> pickTextFile() async {
  try {
    final PlatformFile? f = await FilePicker.pickFile();
    if (f == null) return null;
    return utf8.decode(await f.readAsBytes(), allowMalformed: true);
  } catch (_) {
    return null;
  }
}
