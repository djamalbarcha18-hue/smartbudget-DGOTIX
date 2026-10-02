import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

/// Structured data extracted from a receipt image (by the cloud engine now,
/// by the offline engine later). Pure — no Flutter/IO deps — so it is unit
/// testable and reusable across engines.
class ScannedReceipt {
  const ScannedReceipt({
    required this.merchantName,
    required this.date,
    required this.totalAmount,
    required this.currency,
    required this.category,
    required this.confidence,
    required this.fromCloud,
    this.raw,
    this.invoice,
    this.timings = const ScanTimings(),
    this.imageHash,
  });

  /// The invoice reader's reading (v2 scanner), with its items, totals and
  /// checks. Null for an older scanner that only returns the total.
  final InvoiceReading? invoice;

  /// What the server read, as returned (kept to answer a rescan of the same
  /// photo from memory).
  final Map<String, dynamic>? raw;
  final ScanTimings timings;

  /// SHA-256 of the image sent.
  final String? imageHash;

  /// The reading as the expense to prefill: the invoice reader's total when
  /// there is one.
  factory ScannedReceipt.fromInvoice(
    InvoiceReading r, {
    required Map<String, dynamic> raw,
    required ScanTimings timings,
    String? imageHash,
  }) =>
      ScannedReceipt(
        merchantName: r.supplier ?? '',
        date: r.date,
        totalAmount: r.total ?? 0,
        currency: r.currency ?? '',
        category: r.category ?? '',
        confidence: r.confidence.total,
        fromCloud: true,
        raw: raw,
        invoice: r,
        timings: timings,
        imageHash: imageHash,
      );

  final String merchantName;

  /// Receipt date, or null when the engine could not read one (the UI then
  /// defaults to today rather than guessing).
  final DateTime? date;

  final double totalAmount;

  /// ISO 4217 code (may be empty if the engine could not infer it).
  final String currency;

  /// Best-fit expense category (Arabic canonical label, may be empty).
  final String category;

  /// 0..1 confidence in [totalAmount].
  final double confidence;

  /// True when produced by the cloud (Gemini) engine, false for offline OCR.
  final bool fromCloud;

  /// Parses the `{ ok:true, ... }` payload from the receipt-scan function.
  factory ScannedReceipt.fromCloudJson(Map<String, dynamic> j) {
    return ScannedReceipt(
      merchantName: (j['merchant_name'] ?? '').toString().trim(),
      date: _parseIsoDate(j['date']?.toString()),
      totalAmount: _toDouble(j['total_amount']),
      currency: (j['currency'] ?? '').toString().trim().toUpperCase(),
      category: (j['category'] ?? '').toString().trim(),
      confidence: _toDouble(j['confidence']).clamp(0.0, 1.0),
      fromCloud: true,
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static DateTime? _parseIsoDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

/// Where the time of a scan went, in milliseconds (0 = not measured).
class ScanTimings {
  const ScanTimings({
    this.prepare = 0,
    this.reading = 0,
    this.model = 0,
    this.checks = 0,
    this.fromCache = false,
    this.originalBytes = 0,
    this.sentBytes = 0,
    this.parts = 1,
  });

  /// Hashing the image and looking it up in memory.
  final int prepare;

  /// Sending the image and getting the reading back (includes [model]).
  final int reading;

  /// Of which: the AI model, as measured by the server.
  final int model;

  /// Parsing amounts and checking the arithmetic, on the device.
  final int checks;

  /// Answered from memory: the same photo was read before.
  final bool fromCache;

  /// Size of the photo, and of what was sent after cleanup (0 = not sent).
  final int originalBytes;
  final int sentBytes;

  /// Images sent: 1, or the strips of a very long receipt.
  final int parts;

  int get total => prepare + reading + checks;

  ScanTimings copyWith({int? checks}) => ScanTimings(
        prepare: prepare,
        reading: reading,
        model: model,
        checks: checks ?? this.checks,
        fromCache: fromCache,
        originalBytes: originalBytes,
        sentBytes: sentBytes,
        parts: parts,
      );
}

