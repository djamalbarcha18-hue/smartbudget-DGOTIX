/// Reading the numbers printed on an invoice. Pure (no Flutter, no IO).
///
/// The model copies every amount exactly as printed ("1 250,50", "$12.99",
/// "1.250"); this file decides what they mean. The decimal mark is chosen for
/// the whole invoice from the amounts that are unambiguous, so "1.250" on a
/// French receipt full of "12,99" reads as one thousand two hundred and fifty,
/// and on a receipt full of "12.99" as one point two five (when the currency
/// has 3 decimals) or 1250 otherwise.
library;

/// How one printed amount can be read.
class AmountReading {
  const AmountReading(this.value, {this.alternative});

  /// The value under the invoice's number format.
  final double value;

  /// The other possible value when the text alone is ambiguous ("1.250" as
  /// 1250 or 1.25). The validator may switch to it when only it makes the
  /// line add up.
  final double? alternative;

  bool get ambiguous => alternative != null;
}

/// The invoice's number format: which mark separates decimals.
class InvoiceNumberFormat {
  const InvoiceNumberFormat({required this.decimalMark, required this.decided});

  /// '.' or ','.
  final String decimalMark;

  /// False when no amount on the invoice showed it (a default was used).
  final bool decided;

  String get thousandsMark => decimalMark == '.' ? ',' : '.';

  /// Decides the format from every amount on the invoice.
  /// [currencyDecimals]: 3 for KWD/TND…, 0 for JPY…, otherwise 2.
  static InvoiceNumberFormat detect(
    Iterable<String?> texts, {
    int currencyDecimals = 2,
  }) {
    int dot = 0;
    int comma = 0;
    for (final String? raw in texts) {
      final String? t = _numberPart(raw);
      if (t == null) continue;
      final int lastDot = t.lastIndexOf('.');
      final int lastComma = t.lastIndexOf(',');
      if (lastDot >= 0 && lastComma >= 0) {
        // Both present: the later one is the decimal mark.
        lastDot > lastComma ? dot++ : comma++;
        continue;
      }
      final String sep = lastDot >= 0 ? '.' : (lastComma >= 0 ? ',' : '');
      if (sep.isEmpty) continue;
      if (sep.allMatches(t).length > 1) {
        // "1.250.000": repeated mark = thousands, so the other is decimal.
        sep == '.' ? comma++ : dot++;
        continue;
      }
      final int digitsAfter = t.length - t.lastIndexOf(sep) - 1;
      if (digitsAfter == 1 || digitsAfter == 2) {
        sep == '.' ? dot++ : comma++;
      } else if (digitsAfter == 3 && currencyDecimals == 3) {
        sep == '.' ? dot++ : comma++;
      }
      // 3 digits otherwise: ambiguous, no vote.
    }
    if (dot == 0 && comma == 0) {
      return const InvoiceNumberFormat(decimalMark: '.', decided: false);
    }
    return InvoiceNumberFormat(
        decimalMark: comma > dot ? ',' : '.', decided: true);
  }

  /// Reads one amount, or null when it holds no number. [quantity] reads a
  /// single mark followed by 3 digits as decimals ("0,750" kg), since
  /// quantities in the thousands don't happen on receipts.
  AmountReading? read(
    String? raw, {
    int currencyDecimals = 2,
    bool quantity = false,
  }) {
    final String? t = _numberPart(raw);
    if (t == null) return null;
    final bool negative = _isNegative(raw!);
    double sign(double v) => negative ? -v : v;

    final int lastDot = t.lastIndexOf('.');
    final int lastComma = t.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      final String dec = lastDot > lastComma ? '.' : ',';
      return AmountReading(sign(_parse(t, dec)));
    }
    final String sep = lastDot >= 0 ? '.' : (lastComma >= 0 ? ',' : '');
    if (sep.isEmpty) return AmountReading(sign(double.parse(t)));
    if (sep.allMatches(t).length > 1) {
      // Repeated mark: thousands only.
      return AmountReading(sign(double.parse(t.replaceAll(sep, ''))));
    }
    final int digitsAfter = t.length - t.lastIndexOf(sep) - 1;
    final double asDecimal = _parse(t, sep);
    final double asThousands = double.parse(t.replaceAll(sep, ''));
    if (digitsAfter != 3) {
      // "12,5" / "12.99" / "0.0050": the mark can only be decimal.
      return AmountReading(sign(asDecimal));
    }
    // One mark, 3 digits after it: "1.250" or "1,250".
    if (quantity) return AmountReading(sign(asDecimal));
    if (sep == decimalMark && (decided || currencyDecimals == 3)) {
      return AmountReading(sign(asDecimal), alternative: sign(asThousands));
    }
    if (sep != decimalMark && decided) {
      return AmountReading(sign(asThousands), alternative: sign(asDecimal));
    }
    // Nothing decided: 3 decimals only exist for a few currencies.
    return currencyDecimals == 3
        ? AmountReading(sign(asDecimal), alternative: sign(asThousands))
        : AmountReading(sign(asThousands), alternative: sign(asDecimal));
  }

  static double _parse(String t, String decimal) {
    final String thousands = decimal == '.' ? ',' : '.';
    return double.parse(
        t.replaceAll(thousands, '').replaceAll(decimal, '.'));
  }

  static final RegExp _digitsGroupSpace =
      RegExp("(?<=\\d)[\\s\u00A0\u202F\u2009\u2007']+(?=\\d{3}(?!\\d))");

  /// The digits and separators of an amount, with currency signs, words and
  /// grouping spaces removed; null when there is no digit. Arabic-Indic
  /// digits are converted.
  static String? _numberPart(String? raw) {
    if (raw == null) return null;
    String s = _latinDigits(raw.trim());
    if (!RegExp(r'\d').hasMatch(s)) return null;
    // "1 250,50" / "1'250.50": grouping spaces/apostrophes between digits.
    s = s.replaceAll(_digitsGroupSpace, '');
    // Arabic decimal separator "٫" and thousands "٬".
    s = s.replaceAll('٫', '.').replaceAll('٬', ',');
    final Match? m = RegExp(r'\d[\d.,]*').firstMatch(s);
    if (m == null) return null;
    String n = m.group(0)!;
    // Trailing mark ("12." / "1,250,") is not part of the number.
    while (n.endsWith('.') || n.endsWith(',')) {
      n = n.substring(0, n.length - 1);
    }
    return n.isEmpty ? null : n;
  }

  static bool _isNegative(String raw) {
    final String s = raw.trim();
    return s.startsWith('-') ||
        s.startsWith('−') ||
        (s.startsWith('(') && s.endsWith(')')) ||
        s.endsWith('-');
  }

  static String _latinDigits(String s) {
    const String arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const String persian = '۰۱۲۳۴۵۶۷۸۹';
    final StringBuffer b = StringBuffer();
    for (final int r in s.runes) {
      final String ch = String.fromCharCode(r);
      final int i = arabicIndic.indexOf(ch);
      final int j = persian.indexOf(ch);
      b.write(i >= 0 ? '$i' : (j >= 0 ? '$j' : ch));
    }
    return b.toString();
  }
}
