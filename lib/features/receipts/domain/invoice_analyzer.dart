/// Turns what the model read off an invoice into checked figures. Pure (no
/// Flutter, no IO), so every rule here is unit tested.
///
/// The model only copies text (amounts exactly as printed); everything with a
/// number in it is decided here: the invoice's number format, each amount,
/// the arithmetic checks and the confidence of each field. Nothing is ever
/// filled in: a missing quantity stays null.
library;

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/receipts/domain/invoice_amounts.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

abstract final class InvoiceAnalyzer {
  /// [raw] is the `data` object of the receipt-scan function (v2), with its
  /// short keys: r, inv, dt, cur, sym, sup, cus, cat, it[{n,q,u,t,c}], sub,
  /// dis, tax, tot, paid, due.
  static InvoiceReading analyze(
    Map<String, dynamic> raw, {
    required DateTime today,
    Set<String> knownCategories = const <String>{},
  }) {
    final ({String? code, double confidence, bool conflict}) cur =
        _currency(_str(raw['cur']), _str(raw['sym']));
    final int decimals = cur.code == null ? 2 : _decimalsOf(cur.code!);

    final List<Map<String, dynamic>> rawItems = _dropTranslationLines(<
        Map<String, dynamic>>[
      for (final Object? e in (raw['it'] as List<dynamic>?) ?? const <dynamic>[])
        if (e is Map) e.cast<String, dynamic>(),
    ]);

    // One number format for the whole invoice.
    final InvoiceNumberFormat fmt = InvoiceNumberFormat.detect(
      <String?>[
        for (final Map<String, dynamic> i in rawItems) ...<String?>[
          _str(i['u']),
          _str(i['t']),
        ],
        for (final String k in _summaryKeys) _str(raw[k]),
      ],
      currencyDecimals: decimals,
    );
    AmountReading? amount(String? s) =>
        fmt.read(s, currencyDecimals: decimals);

    final List<_Line> lines = <_Line>[
      for (final Map<String, dynamic> i in rawItems)
        _Line(
          name: _clean(_str(i['n'])) ?? '',
          quantity: fmt.read(_str(i['q']), quantity: true)?.value,
          unitPrice: amount(_str(i['u'])),
          lineTotal: amount(_str(i['t'])),
          legibility: _num(i['c']),
        ),
    ];

    final AmountReading? sub = amount(_str(raw['sub']));
    final AmountReading? dis = amount(_str(raw['dis']));
    final AmountReading? tax = amount(_str(raw['tax']));
    final AmountReading? tot = amount(_str(raw['tot']));
    final AmountReading? paid = amount(_str(raw['paid']));
    final AmountReading? due = amount(_str(raw['due']));

    final DateTime? date = _date(_str(raw['dt']));
    final String? invoiceNumber = _clean(_str(raw['inv']), mask: false);
    final String? category = _str(raw['cat']);

    final _Summary summary = _Summary(
      subtotal: sub,
      discount: dis,
      tax: tax,
      total: tot,
      paid: paid,
      due: due,
    );
    final Set<InvoiceIssue> issues = <InvoiceIssue>{};
    final List<InvoiceItem> items = <InvoiceItem>[
      for (final _Line l in lines) _checkLine(l, decimals, issues),
    ];
    return _finish(
      items: items,
      summary: summary,
      decimals: decimals,
      issues: issues,
      today: today,
      invoiceNumber: invoiceNumber,
      date: date,
      currency: cur,
      supplier: _clean(_str(raw['sup'])),
      customer: _clean(_str(raw['cus'])),
      category: category != null &&
              (knownCategories.isEmpty || knownCategories.contains(category))
          ? category
          : null,
    );
  }

  /// Checks [reading] again after the user corrected some lines.
  static InvoiceReading revalidate(
    InvoiceReading reading,
    List<InvoiceItem> items, {
    required DateTime today,
  }) {
    final Set<InvoiceIssue> issues = <InvoiceIssue>{};
    final List<InvoiceItem> checked = <InvoiceItem>[
      for (final InvoiceItem i in items)
        i.editedByUser
            ? _recheckEdited(i, reading.currencyDecimals, issues)
            : i,
    ];
    if (checked.any((InvoiceItem i) => i.mismatch)) {
      issues.add(InvoiceIssue.lineMismatch);
    }
    if (checked.any((InvoiceItem i) => i.resolvedByContext)) {
      issues.add(InvoiceIssue.amountResolvedByContext);
    }
    AmountReading? keep(double? v) => v == null ? null : AmountReading(v);
    return _finish(
      items: checked,
      summary: _Summary(
        subtotal: keep(reading.subtotal),
        discount: keep(reading.discount),
        tax: keep(reading.tax),
        total: reading.totalComputed ? null : keep(reading.total),
        paid: keep(reading.amountPaid),
        due: keep(reading.amountDue),
      ),
      decimals: reading.currencyDecimals,
      issues: issues,
      today: today,
      invoiceNumber: reading.invoiceNumber,
      date: reading.date,
      currency: (
        code: reading.currency,
        confidence: reading.confidence.currency,
        conflict: false,
      ),
      supplier: reading.supplier,
      customer: reading.customer,
      category: reading.category,
      keepDateConfidence: reading.confidence.date,
      keepNumberConfidence: reading.confidence.invoiceNumber,
    );
  }

  // ---- lines ----

  static InvoiceItem _checkLine(_Line l, int decimals, Set<InvoiceIssue> issues) {
    final double legibility = (l.legibility ?? 0.9).clamp(0.0, 1.0);
    final double? q = l.quantity;
    AmountReading? u = l.unitPrice;
    AmountReading? t = l.lineTotal;

    if (t == null && u == null) {
      return InvoiceItem(
        name: l.name,
        quantity: q,
        confidence: 0,
      );
    }
    if (q == null || u == null || t == null) {
      // Nothing to cross-check: the line is as good as it was legible.
      return InvoiceItem(
        name: l.name,
        quantity: q,
        unitPrice: u?.value,
        lineTotal: t?.value,
        confidence: t == null ? legibility * 0.6 : legibility * 0.95,
      );
    }
    final double tol = _lineTolerance(q, decimals);
    if (_close(q * u.value, t.value, tol)) {
      return InvoiceItem(
        name: l.name,
        quantity: q,
        unitPrice: u.value,
        lineTotal: t.value,
        confidence: _boost(legibility),
      );
    }
    // Try the other reading of an ambiguous amount ("1.250").
    final List<double> unitOptions = <double>[
      u.value,
      if (u.alternative != null) u.alternative!,
    ];
    final List<double> totalOptions = <double>[
      t.value,
      if (t.alternative != null) t.alternative!,
    ];
    for (final double uv in unitOptions) {
      for (final double tv in totalOptions) {
        if (uv == u.value && tv == t.value) continue;
        if (_close(q * uv, tv, tol)) {
          issues.add(InvoiceIssue.amountResolvedByContext);
          return InvoiceItem(
            name: l.name,
            quantity: q,
            unitPrice: uv,
            lineTotal: tv,
            confidence: _boost(legibility) - 0.05,
            resolvedByContext: true,
          );
        }
      }
    }
    issues.add(InvoiceIssue.lineMismatch);
    return InvoiceItem(
      name: l.name,
      quantity: q,
      unitPrice: u.value,
      lineTotal: t.value,
      confidence: legibility < 0.5 ? legibility : 0.5,
      mismatch: true,
    );
  }

  static InvoiceItem _recheckEdited(
      InvoiceItem i, int decimals, Set<InvoiceIssue> issues) {
    final double? q = i.quantity;
    final double? u = i.unitPrice;
    final double? t = i.lineTotal;
    final bool mismatch = q != null &&
        u != null &&
        t != null &&
        !_close(q * u, t, _lineTolerance(q, decimals));
    return i.copyWith(
      confidence: mismatch ? 0.5 : 1,
      mismatch: mismatch,
      resolvedByContext: false,
    );
  }

  // ---- totals ----

  static InvoiceReading _finish({
    required List<InvoiceItem> items,
    required _Summary summary,
    required int decimals,
    required Set<InvoiceIssue> issues,
    required DateTime today,
    required String? invoiceNumber,
    required DateTime? date,
    required ({String? code, double confidence, bool conflict}) currency,
    required String? supplier,
    required String? customer,
    required String? category,
    double? keepDateConfidence,
    double? keepNumberConfidence,
  }) {
    final double minor = _minor(decimals);
    final List<double> lineTotals = <double>[
      for (final InvoiceItem i in items)
        if (i.lineTotal != null) i.lineTotal!,
    ];
    final double? itemsSum = lineTotals.isEmpty
        ? null
        : lineTotals.fold<double>(0, (double a, double b) => a + b);
    final double sumTol = minor * (lineTotals.length / 2).clamp(2, 10);
    final double tol = 2 * minor;

    double? subtotal = summary.subtotal?.value;
    double? total = summary.total?.value;
    final double discount = (summary.discount?.value ?? 0).abs();
    final double tax = (summary.tax?.value ?? 0).abs();

    // Items against the subtotal, trying an ambiguous subtotal both ways.
    bool? itemsMatch;
    if (itemsSum != null && summary.subtotal != null) {
      itemsMatch = _close(itemsSum, subtotal!, sumTol);
      final double? alt = summary.subtotal!.alternative;
      if (!itemsMatch && alt != null && _close(itemsSum, alt, sumTol)) {
        subtotal = alt;
        itemsMatch = true;
        issues.add(InvoiceIssue.amountResolvedByContext);
      }
    }

    // subtotal − discount + tax = total (or the tax was already included).
    bool? totalMatches;
    bool taxIncluded = false;
    final double? base = subtotal ?? (summary.total == null ? null : itemsSum);
    if (summary.total != null && base != null) {
      bool fits(double tv) =>
          _close(base - discount + tax, tv, tol) ||
          (tax > 0 && _close(base - discount, tv, tol));
      totalMatches = fits(total!);
      final double? alt = summary.total!.alternative;
      if (!totalMatches && alt != null && fits(alt)) {
        total = alt;
        totalMatches = true;
        issues.add(InvoiceIssue.amountResolvedByContext);
      }
      if (totalMatches && tax > 0 && !_close(base - discount + tax, total, tol)) {
        taxIncluded = true;
      }
    }
    // Without a subtotal, the items stand in for it (reported as such).
    if (subtotal == null && itemsSum != null && totalMatches != null) {
      itemsMatch = totalMatches;
    }

    // No printed total: calculate it, and say so.
    bool totalComputed = false;
    if (total == null) {
      final double? fromParts = subtotal != null
          ? subtotal - discount + tax
          : (itemsSum != null ? itemsSum - discount + tax : null);
      final double? candidate = fromParts ?? summary.due?.value;
      if (candidate != null && candidate > 0) {
        total = candidate;
        totalComputed = true;
        issues.add(InvoiceIssue.totalComputed);
      } else {
        issues.add(InvoiceIssue.totalMissing);
      }
    }

    if (itemsMatch == false) issues.add(InvoiceIssue.itemsVsSubtotal);
    if (totalMatches == false) issues.add(InvoiceIssue.summaryMismatch);

    final double? paid = summary.paid?.value.abs();
    final double? due = summary.due?.value.abs();
    if (total != null && paid != null && due != null && paid <= total) {
      if (!_close(total - paid, due, tol)) issues.add(InvoiceIssue.dueMismatch);
    }

    if (currency.code == null) issues.add(InvoiceIssue.currencyUnknown);
    if (currency.conflict) issues.add(InvoiceIssue.currencyConflict);

    final double dateConfidence = keepDateConfidence ?? _dateConfidence(date, today);
    if (date == null) issues.add(InvoiceIssue.dateMissing);
    if (date != null && dateConfidence < 0.9) {
      issues.add(InvoiceIssue.dateSuspicious);
    }

    final double totalConfidence = total == null
        ? 0
        : totalComputed
            ? 0.6
            : totalMatches == false
                ? 0.55
                : (totalMatches == true || itemsMatch == true)
                    ? 0.98
                    // Nothing to cross-check it against (a receipt with
                    // only a total): read cleanly, nothing contradicts it.
                    : 0.9;

    return InvoiceReading(
      invoiceNumber: invoiceNumber,
      date: date,
      currency: currency.code,
      supplier: supplier,
      customer: customer,
      category: category,
      items: items,
      subtotal: subtotal,
      discount: summary.discount == null ? null : discount,
      tax: summary.tax == null ? null : tax,
      total: total,
      amountPaid: paid,
      amountDue: due,
      totalComputed: totalComputed,
      currencyDecimals: decimals,
      confidence: InvoiceConfidence(
        invoiceNumber:
            keepNumberConfidence ?? (invoiceNumber == null ? 0 : 0.9),
        date: dateConfidence,
        currency: currency.confidence,
        total: totalConfidence,
      ),
      checks: InvoiceChecks(
        itemsSumMatchesSubtotal: itemsMatch,
        totalMatchesCalculation: totalMatches,
        taxIncludedInSubtotal: taxIncluded,
        issues: issues,
      ),
    );
  }

  static const List<String> _summaryKeys = <String>[
    'sub',
    'dis',
    'tax',
    'tot',
    'paid',
    'due',
  ];

  /// A product printed in several languages comes back as one line with the
  /// amounts and translation lines without any: drop the latter.
  static List<Map<String, dynamic>> _dropTranslationLines(
      List<Map<String, dynamic>> items) {
    bool hasAmount(Map<String, dynamic> i) =>
        _str(i['u']) != null || _str(i['t']) != null;
    return <Map<String, dynamic>>[
      for (int k = 0; k < items.length; k++)
        if (hasAmount(items[k]) ||
            !((k > 0 && hasAmount(items[k - 1])) ||
                (k + 1 < items.length && hasAmount(items[k + 1]))))
          items[k],
    ];
  }

  // ---- currency, date ----

  /// Printed signs and words, mapped to ISO codes.
  static const Map<String, String> _signs = <String, String>{
    'DA': 'DZD', 'DZD': 'DZD', 'د.ج': 'DZD', 'دج': 'DZD', 'DINAR': 'DZD',
    '€': 'EUR', 'EUR': 'EUR', 'EURO': 'EUR', 'EUROS': 'EUR',
    'US\$': 'USD', 'USD': 'USD',
    'C\$': 'CAD', 'CA\$': 'CAD', 'CAD': 'CAD',
    '£': 'GBP', 'GBP': 'GBP',
    'SAR': 'SAR', 'ر.س': 'SAR', 'SR': 'SAR', '﷼': 'SAR',
    'AED': 'AED', 'د.إ': 'AED', 'DHS': 'AED',
    'MAD': 'MAD', 'DH': 'MAD', 'د.م': 'MAD',
    'TND': 'TND', 'DT': 'TND', 'د.ت': 'TND',
    'EGP': 'EGP', 'ج.م': 'EGP', 'E£': 'EGP', 'LE': 'EGP',
  };

  static ({String? code, double confidence, bool conflict}) _currency(
      String? modelCode, String? sign) {
    final Set<String> known = <String>{
      for (final Currency c in Currencies.all) c.code,
    };
    final String? code =
        modelCode != null && known.contains(modelCode.toUpperCase())
            ? modelCode.toUpperCase()
            : null;
    final String? s = sign?.trim().toUpperCase();
    final String? fromSign = s == null
        ? null
        : (_signs[s] ?? (known.contains(s) ? s : null));
    final bool dollarOnly = s == r'$';

    if (code != null && fromSign != null) {
      return code == fromSign
          ? (code: code, confidence: 0.97, conflict: false)
          // The printed sign wins over an inferred code.
          : (code: fromSign, confidence: 0.6, conflict: true);
    }
    if (code != null) {
      // "$" alone fits several dollars: trust the model's reading less.
      return (code: code, confidence: dollarOnly ? 0.75 : 0.85, conflict: false);
    }
    if (fromSign != null) {
      return (code: fromSign, confidence: 0.85, conflict: false);
    }
    if (dollarOnly) return (code: 'USD', confidence: 0.6, conflict: false);
    return (code: null, confidence: 0, conflict: false);
  }

  static int _decimalsOf(String code) {
    for (final Currency c in Currencies.all) {
      if (c.code == code) return c.decimals;
    }
    return 2;
  }

  static DateTime? _date(String? s) {
    if (s == null) return null;
    final Match? m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final int y = int.parse(m.group(1)!);
    final int mo = int.parse(m.group(2)!);
    final int d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final DateTime dt = DateTime(y, mo, d);
    // Rejects 2026-02-30 and the like.
    return dt.month == mo ? dt : null;
  }

  static double _dateConfidence(DateTime? date, DateTime today) {
    if (date == null) return 0;
    final DateTime t = DateTime(today.year, today.month, today.day);
    if (date.isAfter(t.add(const Duration(days: 1)))) return 0.4;
    if (date.isBefore(DateTime(t.year - 3, t.month, t.day))) return 0.6;
    return 0.95;
  }

  // ---- helpers ----

  static double _minor(int decimals) {
    double m = 1;
    for (int i = 0; i < decimals; i++) {
      m /= 10;
    }
    return m;
  }

  /// Printed line totals are rounded, and so is the unit price: each unit
  /// can be off by half a minor unit.
  static double _lineTolerance(double quantity, int decimals) {
    final double minor = _minor(decimals);
    return 2 * minor + quantity.abs() * minor / 2;
  }

  static bool _close(double a, double b, double tol) =>
      (a - b).abs() <= tol + 1e-9;

  static double _boost(double legibility) =>
      (0.5 + legibility / 2).clamp(0.0, 0.99);

  static String? _str(Object? v) {
    if (v == null) return null;
    final String s = v.toString().trim();
    return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static final RegExp _cardLike = RegExp(r'\b\d(?:[ -]?\d){12,18}\b');

  /// Trims, and hides anything that looks like a payment card number.
  static String? _clean(String? s, {bool mask = true}) {
    if (s == null) return null;
    String out = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (mask) {
      out = out.replaceAllMapped(_cardLike, (Match m) {
        final String digits = m.group(0)!.replaceAll(RegExp(r'[ -]'), '');
        return _luhn(digits)
            ? '•••• ${digits.substring(digits.length - 4)}'
            : m.group(0)!;
      });
    }
    return out.isEmpty ? null : out;
  }

  static bool _luhn(String digits) {
    int sum = 0;
    bool dbl = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int d = digits.codeUnitAt(i) - 48;
      if (dbl) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      dbl = !dbl;
    }
    return sum % 10 == 0;
  }
}

class _Line {
  const _Line({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.legibility,
  });
  final String name;
  final double? quantity;
  final AmountReading? unitPrice;
  final AmountReading? lineTotal;
  final double? legibility;
}

class _Summary {
  const _Summary({
    this.subtotal,
    this.discount,
    this.tax,
    this.total,
    this.paid,
    this.due,
  });
  final AmountReading? subtotal;
  final AmountReading? discount;
  final AmountReading? tax;
  final AmountReading? total;
  final AmountReading? paid;
  final AmountReading? due;
}
