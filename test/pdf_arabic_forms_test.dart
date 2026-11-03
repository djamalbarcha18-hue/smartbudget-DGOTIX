/// The PDF library shapes Arabic by rewriting the text into Unicode's Arabic
/// Presentation Forms-B block and looking each form up in the font's cmap. A
/// form the font does not carry is dropped or drawn over its neighbour.
///
/// Tajawal ships without the isolated forms, which silently broke every word
/// whose last letter follows a non-joining letter — شهري, سنوي, أخرى, and the
/// four report period names among them. `tool/patch_arabic_pdf_fonts.py` adds
/// them to the bundled copies; these tests fail if a fresh download is dropped
/// in without running it.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Isolated form -> the letter it stands for, for every Arabic letter the PDF
/// reports can print. The name is the letter, so a failure reads plainly.
const Map<int, String> _isolatedForms = <int, String>{
  0xFE80: 'ء',
  0xFE81: 'آ',
  0xFE83: 'أ',
  0xFE85: 'ؤ',
  0xFE87: 'إ',
  0xFE89: 'ئ',
  0xFE8D: 'ا',
  0xFE8F: 'ب',
  0xFE93: 'ة',
  0xFE95: 'ت',
  0xFE99: 'ث',
  0xFE9D: 'ج',
  0xFEA1: 'ح',
  0xFEA5: 'خ',
  0xFEA9: 'د',
  0xFEAB: 'ذ',
  0xFEAD: 'ر',
  0xFEAF: 'ز',
  0xFEB1: 'س',
  0xFEB5: 'ش',
  0xFEB9: 'ص',
  0xFEBD: 'ض',
  0xFEC1: 'ط',
  0xFEC5: 'ظ',
  0xFEC9: 'ع',
  0xFECD: 'غ',
  0xFED1: 'ف',
  0xFED5: 'ق',
  0xFED9: 'ك',
  0xFEDD: 'ل',
  0xFEE1: 'م',
  0xFEE5: 'ن',
  0xFEE9: 'ه',
  0xFEED: 'و',
  0xFEEF: 'ى',
  0xFEF1: 'ي',
};

void main() {
  late pw.Context context;

  setUpAll(() {
    context = pw.Context(document: pw.Document().document);
  });

  PdfFont open(String path) => pw.Font.ttf(
        ByteData.view(File(path).readAsBytesSync().buffer),
      ).getFont(context);

  for (final String weight in <String>['Regular', 'Bold']) {
    group('Tajawal-$weight', () {
      test('carries every isolated Arabic form the shaper can ask for', () {
        final PdfFont font = open('assets/fonts/Tajawal-$weight.ttf');
        final List<String> missing = <String>[];
        _isolatedForms.forEach((int form, String letter) {
          if (!font.isRuneSupported(form)) {
            missing.add('$letter (U+${form.toRadixString(16).toUpperCase()})');
          }
        });
        expect(missing, isEmpty,
            reason: 'run tool/patch_arabic_pdf_fonts.py — these letters would '
                'vanish from Arabic PDF reports: ${missing.join(', ')}');
      });

      test('still carries the joined forms and the plain letters', () {
        final PdfFont font = open('assets/fonts/Tajawal-$weight.ttf');
        // Final, initial and medial yeh, and the letters themselves: the
        // patch adds mappings, it must never remove one.
        for (final int rune in <int>[
          0xFEF2, 0xFEF3, 0xFEF4, // yeh joined
          0xFEF0, // alef maksura final
          0x064A, 0x0649, 0x0627, 0x0644, // plain letters
          0x0030, 0x0039, 0x0041, // digits and Latin, which Arabic reports use
        ]) {
          expect(font.isRuneSupported(rune), isTrue,
              reason: 'U+${rune.toRadixString(16).toUpperCase()}');
        }
      });
    });
  }

  test('Noto Naskh Arabic, used for Urdu and Persian, was always complete', () {
    final PdfFont font = open('assets/fonts/NotoNaskhArabic-Regular.ttf');
    for (final int form in _isolatedForms.keys) {
      expect(font.isRuneSupported(form), isTrue,
          reason: 'U+${form.toRadixString(16).toUpperCase()}');
    }
  });
}
