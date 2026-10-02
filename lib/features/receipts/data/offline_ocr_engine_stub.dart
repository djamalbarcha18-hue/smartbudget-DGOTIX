import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

/// Offline OCR fallback where there is none: ML Kit has no web version, so
/// on the web the scanner needs the cloud reader.
class OfflineOcrEngine implements ReceiptOcrEngine {
  const OfflineOcrEngine();

  @override
  bool get isAvailable => false;

  @override
  Future<ScannedReceipt> recognize(ReceiptImage image) async {
    throw const ReceiptScanException(ReceiptScanError.offlineUnsupported);
  }
}
