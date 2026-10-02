/// The invoice's lines as the expense's note, so the products stay with the
/// expense after saving. Pure (no Flutter, no IO); language-neutral.
library;

import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

abstract final class InvoiceNotes {
  /// Lines kept in the note; longer invoices end with "… +N".
  static const int maxLines = 40;

  /// e.g.
  ///   # GM-2026-004582
  ///   • Milk 1L  2 × 2.49 = 4.98
  ///   • Bread  3.60
  ///   − 0.75 · + 1.15
  static String? of(InvoiceReading r) {
    if (r.items.isEmpty && r.invoiceNumber == null) return null;
    final int d = r.currencyDecimals;
    String n(double v) => v.toStringAsFixed(d);
    String q(double v) => v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

    final List<String> out = <String>[
      if (r.invoiceNumber != null) '# ${r.invoiceNumber}',
    ];
    final int shown = r.items.length > maxLines ? maxLines - 1 : r.items.length;
    for (final InvoiceItem i in r.items.take(shown)) {
      final String name = i.name.isEmpty ? '—' : i.name;
      final String amount = i.lineTotal == null ? '' : n(i.lineTotal!);
      final String detail = i.quantity != null && i.unitPrice != null
          ? '${q(i.quantity!)} × ${n(i.unitPrice!)} = $amount'
          : amount;
      out.add('• $name  $detail'.trimRight());
    }
    if (r.items.length > shown) out.add('… +${r.items.length - shown}');
    final List<String> adjust = <String>[
      if (r.discount != null && r.discount! > 0) '− ${n(r.discount!)}',
      if (r.tax != null && r.tax! > 0) '+ ${n(r.tax!)}',
    ];
    if (adjust.isNotEmpty) out.add(adjust.join(' · '));
    return out.join('\n');
  }
}
