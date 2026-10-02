// Receipt photo cleanup with the browser's own image engine, behind a
// conditional import. The decisions (where the receipt is, whether the print
// is faded, where to cut) are the shared ones in ReceiptImagePrep.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:smartbudget/features/receipts/data/receipt_image_prep.dart';

JSObject get _document => globalContext['document']! as JSObject;

JSObject _canvas(int w, int h) {
  final JSObject c =
      _document.callMethod<JSObject>('createElement'.toJS, 'canvas'.toJS);
  c['width'] = w.toJS;
  c['height'] = h.toJS;
  return c;
}

JSObject _context(JSObject canvas) =>
    canvas.callMethod<JSObject>('getContext'.toJS, '2d'.toJS);

int _int(JSObject o, String key) => (o[key]! as JSNumber).toDartInt;

Future<Uint8List> _jpeg(JSObject canvas) {
  final Completer<Uint8List> done = Completer<Uint8List>();
  void onBlob(JSObject? blob) {
    if (blob == null) {
      done.completeError(StateError('toBlob'));
      return;
    }
    blob
        .callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS)
        .toDart
        .then((JSArrayBuffer b) => done.complete(b.toDart.asUint8List()),
            onError: done.completeError);
  }

  canvas.callMethod<JSAny?>(
      'toBlob'.toJS, onBlob.toJS, 'image/jpeg'.toJS, 0.82.toJS);
  return done.future;
}

/// The cleaned photo (cropped, gray, faded print stretched, very long
/// receipts in strips), or null when there is nothing to gain or the browser
/// can't: the photo is then sent as is.
Future<PreparedReceipt?> prepareWithPlatform(Uint8List bytes) async {
  if (!globalContext.has('createImageBitmap')) return null;
  JSObject? bitmap;
  try {
    final JSObject blob = (globalContext['Blob']! as JSFunction)
        .callAsConstructor<JSObject>(<JSAny>[bytes.toJS].toJS);
    bitmap = await globalContext
        .callMethod<JSPromise<JSObject>>('createImageBitmap'.toJS, blob)
        .toDart;
    final int w = _int(bitmap, 'width');
    final int h = _int(bitmap, 'height');
    if (w <= 0 || h <= 0) return null;

    // A small copy to find the paper and judge the print.
    const int pw = ReceiptImagePrep.probeWidth;
    final int ph = math.max(1, (h * pw / w).round());
    final JSObject probe = _canvas(pw, ph);
    final JSObject pctx = _context(probe);
    pctx.callMethodVarArgs<JSAny?>('drawImage'.toJS,
        <JSAny?>[bitmap, 0.toJS, 0.toJS, pw.toJS, ph.toJS]);
    final JSObject probeData = pctx.callMethod<JSObject>(
        'getImageData'.toJS, 0.toJS, 0.toJS, pw.toJS, ph.toJS);
    final Uint8ClampedList rgba =
        (probeData['data']! as JSUint8ClampedArray).toDart;
    final List<int> lum = List<int>.filled(pw * ph, 0);
    for (int i = 0; i < pw * ph; i++) {
      lum[i] = (0.299 * rgba[i * 4] +
              0.587 * rgba[i * 4 + 1] +
              0.114 * rgba[i * 4 + 2])
          .round()
          .clamp(0, 255);
    }
    final ReceiptBox? box = ReceiptImagePrep.findReceiptInLuma(lum, pw, ph,
        fullWidth: w, fullHeight: h);
    final int cx = box?.left ?? 0;
    final int cy = box?.top ?? 0;
    final int cw = box?.width ?? w;
    final int ch = box?.height ?? h;

    // Faded print, judged on the paper only.
    final List<int> hist = List<int>.filled(256, 0);
    final int x0 = (cx * pw / w).floor();
    final int x1 = math.min(pw - 1, ((cx + cw) * pw / w).floor());
    final int y0 = (cy * ph / h).floor();
    final int y1 = math.min(ph - 1, ((cy + ch) * ph / h).floor());
    for (int y = y0; y <= y1; y++) {
      for (int x = x0; x <= x1; x++) {
        hist[lum[y * pw + x]]++;
      }
    }
    final (int, int)? faded = ReceiptImagePrep.fadedRange(hist);

    final List<(int, int)> strips = ReceiptImagePrep.stripRanges(cw, ch);
    if (box == null && faded == null && strips.length == 1) return null;

    final List<Uint8List> parts = <Uint8List>[];
    for (final (int top, int sh) in strips) {
      final JSObject c = _canvas(cw, sh);
      final JSObject ctx = _context(c);
      ctx['filter'] = 'grayscale(1)'.toJS;
      ctx.callMethodVarArgs<JSAny?>('drawImage'.toJS, <JSAny?>[
        bitmap, cx.toJS, (cy + top).toJS, cw.toJS, sh.toJS, //
        0.toJS, 0.toJS, cw.toJS, sh.toJS,
      ]);
      if (faded != null) {
        final (int lo, int hi) = faded;
        final double k = 255 / (hi - lo);
        final JSObject data = ctx.callMethod<JSObject>(
            'getImageData'.toJS, 0.toJS, 0.toJS, cw.toJS, sh.toJS);
        final Uint8ClampedList px =
            (data['data']! as JSUint8ClampedArray).toDart;
        for (int i = 0; i < px.length; i += 4) {
          final int g = (0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2])
              .round();
          final int v = ((g - lo) * k).round();
          px[i] = v;
          px[i + 1] = v;
          px[i + 2] = v;
        }
        final JSObject out = (globalContext['ImageData']! as JSFunction)
            .callAsConstructor<JSObject>(px.toJS, cw.toJS, sh.toJS);
        ctx.callMethod<JSAny?>('putImageData'.toJS, out, 0.toJS, 0.toJS);
      }
      parts.add(await _jpeg(c));
    }
    return PreparedReceipt(
      parts: parts,
      originalBytes: bytes.length,
      cropped: box != null,
      enhanced: faded != null,
    );
  } catch (_) {
    return null;
  } finally {
    try {
      bitmap?.callMethod<JSAny?>('close'.toJS);
    } catch (_) {
      // Already released.
    }
  }
}
