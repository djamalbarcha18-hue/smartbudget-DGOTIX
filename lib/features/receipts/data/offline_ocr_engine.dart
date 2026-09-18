import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

/// Offline OCR fallback.
///
/// Google ML Kit Text Recognition runs fully on-device but has NO web
/// implementation, so this ships as unavailable for the current Flutter-Web
/// target. When Android/iOS targets are added, swap this for an ML Kit-backed
/// engine (text recognition + regex for total/date) — the [ReceiptOcrEngine]
/// contract and all call sites stay identical.
class OfflineOcrEngine implements ReceiptOcrEngine {
  const OfflineOcrEngine();

  @override
  bool get isAvailable => false;

  @override
  Future<ScannedReceipt> recognize(ReceiptImage image) async {
    throw const ReceiptScanException(ReceiptScanError.offlineUnsupported);
  }
}
