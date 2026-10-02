import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:smartbudget/features/receipts/domain/offline_receipt_parser.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

/// Offline receipt reading on Android: Google ML Kit's on-device text
/// recognizer (Latin script: French and English; it does not read Arabic),
/// then [OfflineReceiptParser] turns its lines into the same reading as the
/// cloud's, checked the same way. Used when the cloud can't be reached or
/// the user isn't signed in. Nothing leaves the phone.
class OfflineOcrEngine implements ReceiptOcrEngine {
  const OfflineOcrEngine();

  @override
  bool get isAvailable => Platform.isAndroid;

  @override
  Future<ScannedReceipt> recognize(ReceiptImage image) async {
    final List<OcrLine> lines = <OcrLine>[];
    final File file = File('${Directory.systemTemp.path}/sb_receipt_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg');
    final TextRecognizer recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      // Every strip of a long receipt, top to bottom, one after the other.
      final List<List<int>> images =
          image.parts.isNotEmpty ? image.parts : <List<int>>[image.bytes];
      double offset = 0;
      for (final List<int> bytes in images) {
        await file.writeAsBytes(bytes, flush: true);
        final RecognizedText text =
            await recognizer.processImage(InputImage.fromFilePath(file.path));
        double bottom = 0;
        for (final TextBlock b in text.blocks) {
          for (final TextLine l in b.lines) {
            lines.add(OcrLine(
              l.text,
              left: l.boundingBox.left,
              top: l.boundingBox.top + offset,
              right: l.boundingBox.right,
              bottom: l.boundingBox.bottom + offset,
            ));
            if (l.boundingBox.bottom > bottom) bottom = l.boundingBox.bottom;
          }
        }
        offset += bottom + 100;
      }
    } catch (_) {
      throw const ReceiptScanException(ReceiptScanError.unreadable);
    } finally {
      await recognizer.close();
      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {
        // A temporary file: the system clears it eventually.
      }
    }
    if (lines.isEmpty) {
      throw const ReceiptScanException(ReceiptScanError.unreadable);
    }
    final Map<String, dynamic> raw = OfflineReceiptParser.parse(lines);
    final bool anyAmount = <String>['tot', 'sub', 'due']
            .any((String k) => (raw[k] as String).isNotEmpty) ||
        (raw['it'] as List<dynamic>).isNotEmpty;
    if (!anyAmount) {
      throw const ReceiptScanException(ReceiptScanError.noTotal);
    }
    return ScannedReceipt(
      merchantName: '',
      date: null,
      totalAmount: 0,
      currency: '',
      category: '',
      confidence: 0,
      fromCloud: false,
      raw: raw,
    );
  }
}
