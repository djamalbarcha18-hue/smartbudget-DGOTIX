// Web implementation of backup file IO (browser download + file picker).
//
// Kept isolated behind a conditional import (see file_io.dart) so nothing else
// in the app imports dart:html directly.
import 'dart:async';
import 'dart:html' as html;

/// Downloads [text] as a file named [filename] with the given [mime] type.
Future<void> downloadText({
  required String filename,
  required String text,
  required String mime,
}) async {
  // Passing the string as a Blob part lets the browser UTF-8 encode it, so
  // Arabic content is preserved.
  final html.Blob blob = html.Blob(<Object>[text], mime);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

/// Opens a file picker (.json) and returns the chosen file's text, or null if
/// the user cancels.
Future<String?> pickTextFile() async {
  final html.FileUploadInputElement input = html.FileUploadInputElement()
    ..accept = '.json,application/json';
  input.click();

  await input.onChange.first;
  final List<html.File>? files = input.files;
  if (files == null || files.isEmpty) return null;

  final html.FileReader reader = html.FileReader()..readAsText(files.first);
  await reader.onLoadEnd.first;
  final Object? result = reader.result;
  return result is String ? result : null;
}
