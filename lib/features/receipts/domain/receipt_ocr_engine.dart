import 'dart:typed_data';

import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

/// A receipt image to recognize (raw bytes + mime type).
class ReceiptImage {
  const ReceiptImage({
    required this.bytes,
    required this.mimeType,
    this.parts = const <Uint8List>[],
  });
  final Uint8List bytes;
  final String mimeType;

  /// A very long receipt cut into overlapping strips, top to bottom (read
  /// in parallel); empty for a single image ([bytes]).
  final List<Uint8List> parts;
}

/// Pluggable OCR engine. The online (Gemini) and offline (ML Kit, mobile-only,
/// added later) implementations both satisfy this, so the app selects between
/// them without any UI change.
abstract interface class ReceiptOcrEngine {
  /// Whether this engine can run in the current environment.
  bool get isAvailable;

  /// Extracts structured data, or throws [ReceiptScanException].
  Future<ScannedReceipt> recognize(ReceiptImage image);
}

/// Why a scan could not complete — drives the user-facing message.
enum ReceiptScanError {
  cancelled,
  backendUnavailable,
  notSignedIn,
  unreadable,
  noTotal,
  network,
  rateLimited,
  quotaExceeded,
  providerError,
  offlineUnsupported,
  unknown,
}

class ReceiptScanException implements Exception {
  const ReceiptScanException(this.code, {this.status});
  final ReceiptScanError code;
  final int? status;

  @override
  String toString() => 'ReceiptScanException($code, status: $status)';
}
