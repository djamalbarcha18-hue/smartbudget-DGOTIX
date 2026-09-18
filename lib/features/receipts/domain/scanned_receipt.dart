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
  });

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
