import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A receipt photo made ready for reading.
class PreparedReceipt {
  const PreparedReceipt({
    required this.parts,
    required this.originalBytes,
    this.cropped = false,
    this.enhanced = false,
  });

  /// The image(s) to send: one, or several overlapping strips of a very long
  /// receipt, top to bottom.
  final List<Uint8List> parts;
  final int originalBytes;
  final bool cropped;
  final bool enhanced;

  int get sentBytes => parts.fold<int>(0, (int a, Uint8List b) => a + b.length);
}

/// Cleans a receipt photo before it is read, conservatively: anything the
/// steps aren't sure about is left as photographed, since a wrong crop would
/// cost the total and over-processing can blur digits.
///
/// 1. Crop to the receipt: a light paper on a darker background, found on a
///    small copy. Only when the paper clearly stands out, with a margin.
/// 2. Grayscale, and a contrast stretch for faded (thermal) print only.
/// 3. A very long receipt is cut into overlapping strips, read in parallel.
abstract final class ReceiptImagePrep {
  /// Height/width above which a receipt is cut into strips.
  static const double longRatio = 3.2;

  /// Strips never go past this many.
  static const int maxParts = 3;

  /// Each strip repeats this share of its neighbour, so no line is cut.
  static const double overlap = 0.06;

  /// Width and height from the file header alone (no decoding), or null.
  static (int, int)? dimensions(Uint8List bytes) {
    try {
      final img.Decoder? d = img.findDecoderForData(bytes);
      final img.DecodeInfo? info = d?.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) return null;
      return (info.width, info.height);
    } catch (_) {
      return null;
    }
  }

  /// The light path (web, where decoding in Dart is slow and blocks the
  /// screen): the photo is sent as is unless it is a very long receipt,
  /// which is decoded only to be cut into strips.
  static PreparedReceipt splitOnly(Uint8List bytes) {
    final (int, int)? dim = dimensions(bytes);
    if (dim == null || dim.$2 / dim.$1 < longRatio) {
      return PreparedReceipt(parts: <Uint8List>[bytes], originalBytes: bytes.length);
    }
    return prepare(bytes, cleanup: false);
  }

  /// The full path (mobile, run off the UI thread): crop, contrast, strips.
  static PreparedReceipt prepare(Uint8List bytes, {bool cleanup = true}) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return PreparedReceipt(parts: <Uint8List>[bytes], originalBytes: bytes.length);
    }
    img.Image image = decoded;

    final ReceiptBox? box = cleanup ? findReceipt(image) : null;
    final bool cropped = box != null;
    if (box != null) {
      image = img.copyCrop(image,
          x: box.left, y: box.top, width: box.width, height: box.height);
    }

    bool enhanced = false;
    if (cleanup) {
      image = img.grayscale(image);
      enhanced = _stretchIfFaded(image);
    }

    final List<img.Image> strips = splitLong(image);
    final List<Uint8List> parts = <Uint8List>[
      for (final img.Image s in strips) img.encodeJpg(s, quality: 82),
    ];
    // Nothing gained (no crop, no faded print, one part, bigger file): send
    // the photo as is.
    if (!cropped &&
        !enhanced &&
        parts.length == 1 &&
        parts.single.length >= bytes.length) {
      return PreparedReceipt(parts: <Uint8List>[bytes], originalBytes: bytes.length);
    }
    return PreparedReceipt(
      parts: parts,
      originalBytes: bytes.length,
      cropped: cropped,
      enhanced: enhanced,
    );
  }

  /// Width of the small copy the receipt is looked for in.
  static const int probeWidth = 160;

  /// The receipt's bounds in [image], or null when it doesn't clearly stand
  /// out from the background (or already fills the photo).
  static ReceiptBox? findReceipt(img.Image image) {
    final int probeHeight =
        math.max(1, (image.height * probeWidth / image.width).round());
    final img.Image small = img.copyResize(image,
        width: probeWidth,
        height: probeHeight,
        interpolation: img.Interpolation.average);
    final List<int> lum = List<int>.filled(probeWidth * probeHeight, 0);
    for (int y = 0; y < probeHeight; y++) {
      for (int x = 0; x < probeWidth; x++) {
        final img.Pixel p = small.getPixel(x, y);
        lum[y * probeWidth + x] =
            (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
      }
    }
    return findReceiptInLuma(lum, probeWidth, probeHeight,
        fullWidth: image.width, fullHeight: image.height);
  }

  /// The same, from the gray levels of a small copy ([w] × [h], row by row)
  /// of a [fullWidth] × [fullHeight] photo. Shared by every platform.
  static ReceiptBox? findReceiptInLuma(
    List<int> lum,
    int w,
    int h, {
    required int fullWidth,
    required int fullHeight,
  }) {
    // Background and paper levels: the darker and lighter ends of the photo.
    final List<int> sorted = <int>[...lum]..sort();
    final int dark = sorted[(sorted.length * 0.10).floor()];
    final int light = sorted[(sorted.length * 0.90).floor()];
    // Paper and background must differ clearly.
    if (light - dark < 60) return null;
    // Printed lines darken the paper's average, so compare averages of whole
    // columns and rows with the midpoint, not single pixels.
    final double mid = (dark + light) / 2;

    double colMean(int x) {
      int sum = 0;
      for (int y = 0; y < h; y++) {
        sum += lum[y * w + x];
      }
      return sum / h;
    }

    double rowMean(int y, int x0, int x1) {
      int sum = 0;
      for (int x = x0; x <= x1; x++) {
        sum += lum[y * w + x];
      }
      return sum / (x1 - x0 + 1);
    }

    // The paper's columns, then its rows within them. Smoothed, so a line
    // of bold print isn't mistaken for background.
    final (int, int)? cols = _longestRun(
        _smooth(<double>[for (int x = 0; x < w; x++) colMean(x)], 3),
        dark + (light - dark) * 0.35);
    if (cols == null) return null;
    final (int, int)? rows = _longestRun(
        _smooth(<double>[
          for (int y = 0; y < h; y++) rowMean(y, cols.$1, cols.$2),
        ], 4),
        mid);
    if (rows == null) return null;

    final int bw = cols.$2 - cols.$1 + 1;
    final int bh = rows.$2 - rows.$1 + 1;
    final double area = (bw * bh) / (w * h);
    // Too small: probably not the receipt. Nearly all: nothing to crop.
    if (area < 0.2 || area > 0.9) return null;

    final int mx = math.max(2, (bw * 0.04).round());
    final int my = math.max(2, (bh * 0.03).round());
    final int left = math.max(0, cols.$1 - mx);
    final int top = math.max(0, rows.$1 - my);
    final int right = math.min(w - 1, cols.$2 + mx);
    final int bottom = math.min(h - 1, rows.$2 + my);
    final double sx = fullWidth / w;
    final double sy = fullHeight / h;
    return ReceiptBox(
      left: (left * sx).floor(),
      top: (top * sy).floor(),
      width: ((right - left + 1) * sx).ceil(),
      height: ((bottom - top + 1) * sy).ceil(),
    ).clampTo(fullWidth, fullHeight);
  }

  /// Where to cut a [width] × [height] receipt: (top, height) of each
  /// overlapping strip, top to bottom; a single range when it isn't long.
  static List<(int, int)> stripRanges(int width, int height) {
    final double ratio = height / width;
    if (ratio < longRatio) return <(int, int)>[(0, height)];
    final int n = math.min(maxParts, (ratio / 2).ceil());
    final int step = (height / n).ceil();
    final int pad = (step * overlap).round();
    return <(int, int)>[
      for (int i = 0; i < n; i++)
        () {
          final int top = math.max(0, i * step - pad);
          final int bottom = math.min(height, (i + 1) * step + pad);
          return (top, bottom - top);
        }(),
    ];
  }

  /// The gray range to stretch to full contrast, from a histogram of gray
  /// levels (256 counts); null when the print isn't faded.
  static (int, int)? fadedRange(List<int> hist) {
    final int total = hist.fold<int>(0, (int a, int b) => a + b);
    if (total == 0) return null;
    int lo = 0;
    int hi = 255;
    int acc = 0;
    for (int i = 0; i < 256; i++) {
      acc += hist[i];
      if (acc >= total * 0.01) {
        lo = i;
        break;
      }
    }
    acc = 0;
    for (int i = 255; i >= 0; i--) {
      acc += hist[i];
      if (acc >= total * 0.01) {
        hi = i;
        break;
      }
    }
    // Dark text already near black and paper near white: leave it.
    if (hi - lo >= 170 || hi - lo < 20) return null;
    return (lo, hi);
  }

  /// Cuts a very long receipt into overlapping strips (top to bottom).
  static List<img.Image> splitLong(img.Image image) => <img.Image>[
        for (final (int top, int h) in stripRanges(image.width, image.height))
          if (top == 0 && h == image.height)
            image
          else
            img.copyCrop(image, x: 0, y: top, width: image.width, height: h),
      ];

  /// Spreads the gray levels of faded print over the full range. Returns
  /// whether it was needed (a well-contrasted photo is left untouched).
  static bool _stretchIfFaded(img.Image image) {
    final List<int> hist = List<int>.filled(256, 0);
    for (final img.Pixel p in image) {
      hist[p.r.toInt().clamp(0, 255)]++;
    }
    final (int, int)? range = fadedRange(hist);
    if (range == null) return false;
    final (int lo, int hi) = range;
    final double k = 255 / (hi - lo);
    for (final img.Pixel p in image) {
      final int v = ((p.r - lo) * k).round().clamp(0, 255);
      p
        ..r = v
        ..g = v
        ..b = v;
    }
    return true;
  }

  /// Moving average over ±[radius] values.
  static List<double> _smooth(List<double> v, int radius) => <double>[
        for (int i = 0; i < v.length; i++)
          () {
            final int a = math.max(0, i - radius);
            final int b = math.min(v.length - 1, i + radius);
            double sum = 0;
            for (int j = a; j <= b; j++) {
              sum += v[j];
            }
            return sum / (b - a + 1);
          }(),
      ];

  /// The longest stretch of values ≥ [min], as (first, last) index.
  static (int, int)? _longestRun(List<double> v, double min) {
    int bestStart = -1;
    int bestLen = 0;
    int start = -1;
    for (int i = 0; i <= v.length; i++) {
      final bool on = i < v.length && v[i] >= min;
      if (on && start < 0) start = i;
      if (!on && start >= 0) {
        if (i - start > bestLen) {
          bestLen = i - start;
          bestStart = start;
        }
        start = -1;
      }
    }
    return bestLen == 0 ? null : (bestStart, bestStart + bestLen - 1);
  }
}

class ReceiptBox {
  const ReceiptBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final int left;
  final int top;
  final int width;
  final int height;

  ReceiptBox clampTo(int w, int h) {
    final int l = left.clamp(0, w - 1);
    final int t = top.clamp(0, h - 1);
    return ReceiptBox(
      left: l,
      top: t,
      width: math.min(width, w - l),
      height: math.min(height, h - t),
    );
  }
}

/// [ReceiptImagePrep.prepare] as a top-level function, for `compute`.
PreparedReceipt prepareReceiptInBackground(Uint8List bytes) =>
    ReceiptImagePrep.prepare(bytes);

