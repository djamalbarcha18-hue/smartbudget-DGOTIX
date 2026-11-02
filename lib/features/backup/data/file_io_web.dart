// Web implementation of backup file IO (browser download + file picker).
//
// Kept isolated behind a conditional import (see file_io.dart) so nothing else
// in the app reaches for the DOM.
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands [blob] to the browser as a download named [filename].
void _save(web.Blob blob, String filename) {
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = filename
        ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Downloads [text] as a file named [filename] with the given [mime] type.
Future<void> downloadText({
  required String filename,
  required String text,
  required String mime,
}) async {
  // Passing the string as a Blob part lets the browser UTF-8 encode it, so
  // Arabic content is preserved.
  _save(
    web.Blob(<JSAny>[text.toJS].toJS, web.BlobPropertyBag(type: mime)),
    filename,
  );
}

/// Downloads binary [bytes] (e.g. a PNG image) as [filename].
Future<void> downloadBytes({
  required String filename,
  required List<int> bytes,
  required String mime,
}) async {
  // Must be typed data: a plain List<int> would be stringified ("1,2,3").
  final Uint8List data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  _save(
    web.Blob(<JSAny>[data.toJS].toJS, web.BlobPropertyBag(type: mime)),
    filename,
  );
}

/// Opens the browser's file picker limited to [accept] and returns the chosen
/// file. Like the picker it wraps, it settles only once a file is chosen:
/// a cancelled dialog fires no event in any browser.
Future<web.File?> _pickOne(String accept) async {
  final web.HTMLInputElement input =
      web.document.createElement('input') as web.HTMLInputElement
        ..type = 'file'
        ..accept = accept;
  final Completer<void> chosen = Completer<void>();
  input.onchange = (web.Event _) {
    if (!chosen.isCompleted) chosen.complete();
  }.toJS;
  input.click();
  await chosen.future;
  final web.FileList? files = input.files;
  if (files == null || files.length == 0) return null;
  return files.item(0);
}

/// Reads [file] once the browser has it, as text or as bytes.
Future<JSAny?> _read(web.File file, {required bool asText}) async {
  final web.FileReader reader = web.FileReader();
  final Completer<void> done = Completer<void>();
  reader.onloadend = (web.Event _) {
    if (!done.isCompleted) done.complete();
  }.toJS;
  if (asText) {
    reader.readAsText(file);
  } else {
    reader.readAsArrayBuffer(file);
  }
  await done.future;
  return reader.result;
}

/// Opens a file picker (.json) and returns the chosen file's text, or null if
/// the user cancels.
Future<String?> pickTextFile() async {
  final web.File? file = await _pickOne('.json,application/json');
  if (file == null) return null;
  final Object? text = (await _read(file, asText: true))?.dartify();
  return text is String ? text : null;
}

/// Prompts the user to choose a spreadsheet (Excel or CSV) and returns its
/// name and bytes, or null when nothing was chosen.
Future<({String name, Uint8List bytes})?> pickDataFile() async {
  final web.File? file = await _pickOne(
    '.csv,.xlsx,.xls,.tsv,.txt,text/csv,'
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  if (file == null) return null;
  final JSAny? result = await _read(file, asText: false);
  if (result == null) return null;
  return (
    name: file.name,
    bytes: (result as JSArrayBuffer).toDart.asUint8List(),
  );
}
