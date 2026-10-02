/// "This invoice may be a duplicate": a hint only, the user can always save.
/// Pure (no Flutter, no IO).
library;

import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

/// The identifying parts of an invoice read earlier.
class InvoiceFingerprint {
  const InvoiceFingerprint({
    this.invoiceNumber,
    this.date,
    this.supplier,
    this.total,
    this.itemCount = 0,
  });

  final String? invoiceNumber;
  final DateTime? date;
  final String? supplier;
  final double? total;
  final int itemCount;

  factory InvoiceFingerprint.of(InvoiceReading r) => InvoiceFingerprint(
        invoiceNumber: r.invoiceNumber,
        date: r.date,
        supplier: r.supplier,
        total: r.total,
        itemCount: r.items.length,
      );
}

/// An expense already recorded, as far as matching is concerned.
class RecordedExpense {
  const RecordedExpense({
    required this.date,
    required this.amount,
    required this.currency,
    this.description = '',
  });
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
}

abstract final class InvoiceDuplicates {
  /// True when [r] matches an invoice the user already added ([previous]) or
  /// an expense already recorded on the same day for the same amount.
  static bool isLikelyDuplicate(
    InvoiceReading r, {
    Iterable<InvoiceFingerprint> previous = const <InvoiceFingerprint>[],
    Iterable<RecordedExpense> expenses = const <RecordedExpense>[],
  }) {
    for (final InvoiceFingerprint p in previous) {
      if (_sameInvoice(r, p)) return true;
    }
    final double? total = r.total;
    final DateTime? date = r.date;
    if (total == null || date == null) return false;
    for (final RecordedExpense e in expenses) {
      if (!_sameDay(e.date, date)) continue;
      if (r.currency != null && e.currency != r.currency) continue;
      if ((e.amount - total).abs() > 0.01) continue;
      final String sup = _norm(r.supplier);
      final String desc = _norm(e.description);
      if (sup.isEmpty || desc.isEmpty || desc.contains(sup) || sup.contains(desc)) {
        return true;
      }
    }
    return false;
  }

  static bool _sameInvoice(InvoiceReading r, InvoiceFingerprint p) {
    final String a = _norm(r.invoiceNumber);
    final String b = _norm(p.invoiceNumber);
    final bool sameSupplier =
        _norm(r.supplier).isEmpty || _norm(r.supplier) == _norm(p.supplier);
    if (a.isNotEmpty && b.isNotEmpty) return a == b && sameSupplier;
    // No invoice number: date, supplier, total and item count together.
    return r.date != null &&
        p.date != null &&
        _sameDay(r.date!, p.date!) &&
        _norm(r.supplier).isNotEmpty &&
        _norm(r.supplier) == _norm(p.supplier) &&
        r.total != null &&
        p.total != null &&
        (r.total! - p.total!).abs() <= 0.01 &&
        r.items.length == p.itemCount;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _norm(String? s) =>
      (s ?? '').toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
}
