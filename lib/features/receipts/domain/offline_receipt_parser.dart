/// Reading a receipt from on-device OCR text (no network). Pure (no Flutter,
/// no IO), unit tested.
///
/// On-device OCR returns lines of text with their position, not meaning.
/// This puts the lines that sit at the same height back into rows, finds the
/// totals by their keywords (French, English, Arabic), the item lines above
/// them, the date, number and store, and returns the same short-key reading
/// as the cloud reader, so the same checks and review screen apply. It is a
/// fallback: items get a modest legibility, so readings are reviewed rather
/// than trusted, and nothing missing is filled in.
library;

/// One line of OCR text and its box on the image.
class OcrLine {
  const OcrLine(this.text, {this.left = 0, this.top = 0, this.right = 0, this.bottom = 0});
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerY => (top + bottom) / 2;
  double get height => (bottom - top).abs();
}

abstract final class OfflineReceiptParser {
  /// Legibility given to every line read on the device.
  static const double legibility = 0.75;

  static Map<String, dynamic> parse(List<OcrLine> lines) {
    final List<String> rows = toRows(lines);

    String? sym;
    for (final String r in rows) {
      sym ??= _currencySign(r);
    }

    String sub = '', dis = '', tax = '', tot = '', paid = '', due = '';
    int firstSummary = rows.length;
    for (int i = 0; i < rows.length; i++) {
      final String r = rows[i];
      final String low = _fold(r);
      if (_isNoise(low)) continue;
      final String? amount = _lastAmountText(r);
      if (amount == null) continue;
      final _Kind? kind = _summaryKind(low);
      if (kind == null) continue;
      if (i < firstSummary) firstSummary = i;
      switch (kind) {
        case _Kind.subtotal:
          if (sub.isEmpty) sub = amount;
        case _Kind.discount:
          if (dis.isEmpty) dis = amount;
        case _Kind.tax:
          if (tax.isEmpty) tax = amount;
        case _Kind.total:
          // The first grand total wins (later "total" lines repeat it or are
          // the payment breakdown).
          if (tot.isEmpty) tot = amount;
        case _Kind.paid:
          if (paid.isEmpty) paid = amount;
        case _Kind.due:
          if (due.isEmpty) due = amount;
      }
    }

    // Items: rows above the first total line that end with amounts.
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    String? pendingName;
    for (int i = 0; i < firstSummary; i++) {
      final String r = rows[i];
      final String low = _fold(r);
      if (_isNoise(low) || _isHeaderLine(low)) {
        pendingName = null;
        continue;
      }
      // "2 x 2.49" / "3 × 1,20": the quantity, taken out of the row.
      String q = '';
      String row = r;
      final Match? times =
          RegExp(r'(?:^|\s)(\d+(?:[.,]\d+)?)\s*[xX×*](?=\s|$)').firstMatch(row);
      if (times != null) {
        q = times.group(1)!;
        row = '${row.substring(0, times.start)} ${row.substring(times.end)}';
      }
      final List<String> nums = _numbers(row);
      final bool hasLetters = RegExp(r'\p{L}{2,}', unicode: true).hasMatch(row);
      if (nums.isEmpty) {
        // A name whose amounts are on the next line.
        pendingName = hasLetters ? r.trim() : null;
        continue;
      }
      final String name = hasLetters ? _nameOf(row) : (pendingName ?? '');
      pendingName = null;
      if (name.isEmpty) continue;
      String u = '';
      final String t = nums.last;
      if (nums.length >= 3) {
        q = q.isEmpty ? nums[nums.length - 3] : q;
        u = nums[nums.length - 2];
      } else if (nums.length == 2) {
        final String first = nums.first;
        if (q.isEmpty && RegExp(r'^\d{1,3}$').hasMatch(first)) {
          q = first;
        } else {
          u = first;
        }
      }
      items.add(<String, dynamic>{
        'n': name, 'q': q, 'u': u, 't': t, 'c': legibility, //
      });
    }

    return <String, dynamic>{
      'r': true,
      'src': 'device',
      'inv': _invoiceNumber(rows) ?? '',
      'dt': _date(rows) ?? '',
      'cur': '',
      'sym': sym ?? '',
      'sup': _store(rows, firstSummary) ?? '',
      'cus': '',
      'cat': '',
      'it': items,
      'sub': sub, 'dis': dis, 'tax': tax, 'tot': tot, 'paid': paid, 'due': due,
    };
  }

  /// Lines side by side on the image (name on the left, price on the
  /// right) become one row, top to bottom.
  static List<String> toRows(List<OcrLine> lines) {
    final List<OcrLine> sorted = <OcrLine>[...lines]
      ..sort((OcrLine a, OcrLine b) => a.centerY.compareTo(b.centerY));
    final List<List<OcrLine>> rows = <List<OcrLine>>[];
    for (final OcrLine l in sorted) {
      if (l.text.trim().isEmpty) continue;
      final List<OcrLine>? last = rows.isEmpty ? null : rows.last;
      if (last != null) {
        final OcrLine ref = last.first;
        final double tol = (ref.height > 0 ? ref.height : 10) * 0.5;
        if ((l.centerY - ref.centerY).abs() <= tol) {
          last.add(l);
          continue;
        }
      }
      rows.add(<OcrLine>[l]);
    }
    return <String>[
      for (final List<OcrLine> r in rows)
        (r..sort((OcrLine a, OcrLine b) => a.left.compareTo(b.left)))
            .map((OcrLine l) => l.text.trim())
            .join('  '),
    ];
  }

  // ---- amounts ----

  static final RegExp _token = RegExp(r'^[-−(]?\d+(?:[.,]\d+)*[)-]?$');

  /// Numeric tokens of a row, left to right; "1 250,00" style groups are
  /// joined when they can't be a quantity.
  static List<String> _numbers(String row) {
    final List<String> toks = <String>[
      for (final String t in row.split(RegExp(r'\s+')))
        if (_token.hasMatch(_stripCurrency(t))) _stripCurrency(t),
    ];
    final List<String> out = <String>[];
    for (final String t in toks) {
      final bool groupTail = RegExp(r'^\d{3}[.,]\d{2}$').hasMatch(t);
      if (groupTail &&
          out.length >= 2 &&
          RegExp(r'^\d{1,3}$').hasMatch(out.last)) {
        out[out.length - 1] = '${out.last} $t';
      } else {
        out.add(t);
      }
    }
    return out;
  }

  /// The amount at the end of a summary row (one amount: grouping spaces
  /// belong to it).
  static String? _lastAmountText(String row) {
    final Match? m = RegExp(r'(-?\d{1,3}(?:[  ]\d{3})+(?:[.,]\d{1,3})?|-?\d+(?:[.,]\d+)*)\s*\D{0,4}$')
        .firstMatch(_stripCurrencyWords(row));
    return m?.group(1);
  }

  static String _stripCurrency(String t) => t.replaceAll(
      RegExp(r'^(?:DA|DZD|EUR|USD|MAD|TND|€|\$|£)|(?:DA|DZD|EUR|USD|MAD|TND|€|\$|£|د\.ج)$'),
      '');

  static String _stripCurrencyWords(String row) => row
      .replaceAll(RegExp(r'\b(?:DA|DZD|EUR|USD|MAD|TND|DH|DT)\b'), '')
      .replaceAll(RegExp(r'[€$£]|د\.ج'), '')
      .trimRight();

  /// The words before the first amount ("Lait 1L" keeps its "1L").
  static String _nameOf(String row) {
    final List<String> words = <String>[];
    for (final String t in row.split(RegExp(r'\s+'))) {
      if (t.isEmpty) continue;
      if (_token.hasMatch(_stripCurrency(t))) break;
      words.add(t);
    }
    return words.join(' ').trim();
  }

  static String? _currencySign(String row) {
    final Match? m = RegExp(r'\b(DZD|EUR|USD|MAD|TND|GBP|SAR|AED|CAD)\b|\b(DA)\b|(€)|(د\.ج)|(£)')
        .firstMatch(row);
    if (m == null) return null;
    for (int g = 1; g <= m.groupCount; g++) {
      if (m.group(g) != null) return m.group(g);
    }
    return null;
  }

  // ---- keywords ----

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  static _Kind? _summaryKind(String low) {
    bool has(List<String> words) => words.any(low.contains);
    if (has(<String>['sous-total', 'sous total', 'subtotal', 'sub-total', 'sub total', 'total ht', 'المجموع الفرعي'])) {
      return _Kind.subtotal;
    }
    if (has(<String>['remise', 'discount', 'reduction', 'الخصم', 'تخفيض'])) return _Kind.discount;
    if (has(<String>['reste a payer', 'balance', 'reste du', 'المتبقي'])) return _Kind.due;
    if (has(<String>['tva', 'vat', 'tax', 'الضريبة'])) return _Kind.tax;
    if (has(<String>['especes', 'cash', 'paye', 'paid', 'tendered', 'cb ', 'carte', 'card', 'المدفوع', 'نقدا'])) {
      return _Kind.paid;
    }
    if (has(<String>['total', 'net a payer', 'a payer', 'amount due', 'montant', 'الإجمالي', 'المجموع', 'المبلغ'])) {
      return _Kind.total;
    }
    return null;
  }

  static bool _isNoise(String low) =>
      RegExp(r'(tel|tél|phone|fax|www\.|https?:|@|merci|thank|bienvenue|welcome|caissi|cashier|terminal|auth|transaction|rendu|monnaie|change due|شكرا|هاتف)')
          .hasMatch(low) ||
      RegExp(r'\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{1,4}').hasMatch(low);

  /// A column header or the invoice's own details, not a product: several
  /// header words, or one with no amount.
  static bool _isHeaderLine(String low) {
    final int words = RegExp(
            r'(facture|invoice|ticket|recu|receipt|n°|date|heure|time|qte|qty|quantite|designation|description|article|prix|price|p\.u|montant|amount|فاتورة|التاريخ|الكمية)')
        .allMatches(low)
        .length;
    return words >= 2 || (words == 1 && _numbers(low).isEmpty);
  }

  static String? _invoiceNumber(List<String> rows) {
    final RegExp re = RegExp(
        r'(?:facture|invoice|ticket|recu|reçu|receipt|bon)\s*(?:n[°o]\.?|no\.?|#|num(?:ero|éro)?)?\s*[:#]?\s*([A-Z0-9][A-Z0-9\-/]{2,})',
        caseSensitive: false);
    for (final String r in rows) {
      final Match? m = re.firstMatch(r);
      if (m != null) return m.group(1);
    }
    final RegExp short = RegExp(r'\b(?:n°|no\.|#)\s*([A-Z0-9][A-Z0-9\-/]{2,})', caseSensitive: false);
    for (final String r in rows) {
      final Match? m = short.firstMatch(r);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// YYYY-MM-DD from dd/mm/yyyy, dd-mm-yy, yyyy-mm-dd (day first unless the
  /// second number can only be a day).
  static String? _date(List<String> rows) {
    String two(int v) => v.toString().padLeft(2, '0');
    for (final String r in rows) {
      final Match? iso = RegExp(r'\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b').firstMatch(r);
      if (iso != null) {
        return '${iso.group(1)}-${two(int.parse(iso.group(2)!))}-${two(int.parse(iso.group(3)!))}';
      }
      final Match? m = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b').firstMatch(r);
      if (m != null) {
        int a = int.parse(m.group(1)!);
        int b = int.parse(m.group(2)!);
        int y = int.parse(m.group(3)!);
        if (y < 100) y += 2000;
        if (b > 12 && a <= 12) {
          final int t = a;
          a = b;
          b = t;
        }
        if (a < 1 || a > 31 || b < 1 || b > 12) continue;
        return '$y-${two(b)}-${two(a)}';
      }
    }
    return null;
  }

  /// The store: the first line at the top with words and no amount.
  static String? _store(List<String> rows, int before) {
    for (int i = 0; i < before && i < 4; i++) {
      final String r = rows[i];
      final String low = _fold(r);
      if (_isNoise(low) || _isHeaderLine(low)) continue;
      if (_numbers(r).isNotEmpty) continue;
      if (RegExp(r'\p{L}{3,}', unicode: true).hasMatch(r)) return r.trim();
    }
    return null;
  }
}

enum _Kind { subtotal, discount, tax, total, paid, due }
