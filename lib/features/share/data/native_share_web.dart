// Web Share API, kept behind a conditional import (see native_share.dart).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

enum NativeShareResult { shared, cancelled, unsupported }

JSObject get _navigator => globalContext['navigator']! as JSObject;

bool get canShareNatively => _navigator.has('share');

/// Opens the system share sheet. With [pngBytes] the image is attached, and the
/// call reports [NativeShareResult.unsupported] when the browser can't share
/// files (desktop browsers mostly), so the caller can download it instead.
Future<NativeShareResult> shareNatively({
  String? title,
  String? text,
  String? url,
  Uint8List? pngBytes,
  String? filename,
}) async {
  final JSObject nav = _navigator;
  if (!nav.has('share')) return NativeShareResult.unsupported;

  final JSObject data = JSObject();
  if (title != null) data['title'] = title.toJS;
  if (text != null) data['text'] = text.toJS;
  if (url != null) data['url'] = url.toJS;

  if (pngBytes != null) {
    final JSObject options = JSObject()..['type'] = 'image/png'.toJS;
    final JSObject file = (globalContext['File']! as JSFunction)
        .callAsConstructor<JSObject>(<JSAny>[pngBytes.toJS].toJS,
            (filename ?? 'smartbudget.png').toJS, options);
    data['files'] = <JSAny>[file].toJS;
    final bool canFiles = nav.has('canShare') &&
        nav.callMethod<JSBoolean>('canShare'.toJS, data).toDart;
    if (!canFiles) return NativeShareResult.unsupported;
  }

  try {
    await nav.callMethod<JSPromise<JSAny?>>('share'.toJS, data).toDart;
    return NativeShareResult.shared;
  } catch (e) {
    return e.toString().contains('AbortError')
        ? NativeShareResult.cancelled
        : NativeShareResult.unsupported;
  }
}
