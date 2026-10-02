import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:smartbudget/features/receipts/data/receipt_image_prep.dart';

/// A photo: [bg] background with a light receipt (and dark text lines).
img.Image photo({
  int w = 1280,
  int h = 1707,
  int bg = 55,
  int paper = 235,
  int ink = 30,
  (int, int, int, int)? receipt = (300, 150, 680, 1400),
}) {
  final img.Image im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(bg, bg + 5, bg + 10));
  if (receipt != null) {
    final (int x, int y, int rw, int rh) = receipt;
    img.fillRect(im, x1: x, y1: y, x2: x + rw, y2: y + rh,
        color: img.ColorRgb8(paper, paper, paper - 5));
    for (int line = y + 40; line < y + rh - 40; line += 36) {
      img.fillRect(im, x1: x + 30, y1: line, x2: x + rw - 60, y2: line + 12,
          color: img.ColorRgb8(ink, ink, ink));
    }
  }
  return im;
}

Uint8List jpg(img.Image im) => img.encodeJpg(im, quality: 80);

void main() {
  test('crops the background around the receipt, with a margin', () {
    final img.Image p = photo();
    final ReceiptBox? box = ReceiptImagePrep.findReceipt(p);
    expect(box, isNotNull);
    // The receipt spans x 300–980, y 150–1550: kept whole.
    expect(box!.left, lessThanOrEqualTo(300));
    expect(box.top, lessThanOrEqualTo(150));
    expect(box.left + box.width, greaterThanOrEqualTo(980));
    expect(box.top + box.height, greaterThanOrEqualTo(1550));
    // And most of the background is gone.
    expect(box.width, lessThan(820));

    final Stopwatch sw = Stopwatch()..start();
    final PreparedReceipt r = ReceiptImagePrep.prepare(jpg(p));
    // ignore: avoid_print
    print('prepare: ${sw.elapsedMilliseconds} ms, '
        '${r.originalBytes ~/ 1024} KB -> ${r.sentBytes ~/ 1024} KB');
    expect(r.cropped, isTrue);
    expect(r.parts, hasLength(1));
    expect(r.sentBytes, lessThan(r.originalBytes));
  });

  test('a receipt filling the photo is not cropped', () {
    final img.Image p = photo(bg: 235, receipt: null);
    expect(ReceiptImagePrep.findReceipt(p), isNull);
  });

  test('no clear paper/background contrast: not cropped', () {
    final img.Image p = photo(bg: 190, paper: 215);
    expect(ReceiptImagePrep.findReceipt(p), isNull);
  });

  test('faded print is stretched, sharp print left alone', () {
    final PreparedReceipt faded = ReceiptImagePrep.prepare(
        jpg(photo(bg: 120, paper: 200, ink: 150, receipt: (0, 0, 1279, 1706))));
    expect(faded.enhanced, isTrue);
    final PreparedReceipt sharp = ReceiptImagePrep.prepare(
        jpg(photo(bg: 240, paper: 245, ink: 10, receipt: (0, 0, 1279, 1706))));
    expect(sharp.enhanced, isFalse);
  });

  test('a very long receipt is cut into overlapping strips', () {
    final img.Image long = photo(w: 640, h: 4096, bg: 240, receipt: null);
    final List<img.Image> strips = ReceiptImagePrep.splitLong(long);
    expect(strips.length, 3);
    final int covered = strips.fold<int>(0, (int a, img.Image s) => a + s.height);
    expect(covered, greaterThan(4096), reason: 'strips overlap');
    expect(ReceiptImagePrep.splitLong(photo()).length, 1);
  });

  test('an unreadable file is passed through untouched', () {
    final Uint8List junk = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final PreparedReceipt r = ReceiptImagePrep.prepare(junk);
    expect(r.parts.single, same(junk));
  });

  test('light path: header-only check, photo untouched unless very long', () {
    final Uint8List normal = jpg(photo());
    expect(ReceiptImagePrep.dimensions(normal), (1280, 1707));
    expect(ReceiptImagePrep.splitOnly(normal).parts.single, same(normal));
    final PreparedReceipt long = ReceiptImagePrep.splitOnly(
        jpg(photo(w: 640, h: 4096, bg: 240, receipt: null)));
    expect(long.parts.length, 3);
    expect(long.cropped, isFalse);
    expect(long.enhanced, isFalse);
  });
}
