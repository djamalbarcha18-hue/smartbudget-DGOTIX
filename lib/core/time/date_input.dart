/// Dates typed by hand, read the same way in every language: year first,
/// "2026/10/25". Kept apart from display (which follows the app language, see
/// `date_text.dart`) and from storage (which keeps each model's own format).
abstract final class DateInput {
  /// "yyyy/MM/dd", the format typed and shown in date fields.
  static String format(DateTime d) => '${d.year.toString().padLeft(4, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}';

  static final RegExp _ymd =
      RegExp(r'^(\d{4})\s*([/\-.])\s*(\d{1,2})\s*\2\s*(\d{1,2})$');

  /// Reads "2026/10/25" (also with "-" or "." between the parts, one-digit
  /// month or day, surrounding spaces, Arabic, Persian, Devanagari or
  /// full-width digits and invisible direction marks). Returns the calendar
  /// day at local midnight, or null when it isn't a real date ("2026/02/30",
  /// month 13, day 00…).
  static DateTime? parse(String? input) {
    if (input == null) return null;
    final RegExpMatch? m = _ymd.firstMatch(clean(input));
    if (m == null) return null;
    return dateOf(int.parse(m[1]!), int.parse(m[3]!), int.parse(m[4]!));
  }

  /// The calendar day [year]-[month]-[day], or null when it doesn't exist.
  static DateTime? dateOf(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final DateTime d = DateTime(year, month, day);
    // DateTime rolls over (Feb 30 → Mar 2): reject what changed.
    return d.year == year && d.month == month && d.day == day ? d : null;
  }

  /// Latin digits and plain separators, without the invisible characters
  /// that right-to-left text and copy-paste leave behind.
  static String clean(String input) {
    final StringBuffer b = StringBuffer();
    for (final int r in input.runes) {
      if (_invisible(r)) continue;
      if (r >= 0x0660 && r <= 0x0669) {
        b.writeCharCode(0x30 + r - 0x0660); // Arabic-Indic
      } else if (r >= 0x06F0 && r <= 0x06F9) {
        b.writeCharCode(0x30 + r - 0x06F0); // Persian
      } else if (r >= 0x0966 && r <= 0x096F) {
        b.writeCharCode(0x30 + r - 0x0966); // Devanagari
      } else if (r >= 0xFF10 && r <= 0xFF19) {
        b.writeCharCode(0x30 + r - 0xFF10); // full-width
      } else if (r == 0xFF0F || r == 0x2215 || r == 0x2044) {
        b.write('/'); // full-width solidus, division and fraction slashes
      } else if (r == 0xFF0D || r == 0x2010 || r == 0x2011 || r == 0x2212) {
        b.write('-');
      } else if (r == 0xFF0E || r == 0x3002) {
        b.write('.');
      } else if (r == 0x00A0 || r == 0x202F || r == 0x3000) {
        b.write(' ');
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString().trim();
  }

  /// Direction marks, embeddings, isolates, the zero-width characters and
  /// the byte-order mark.
  static bool _invisible(int r) =>
      r == 0x061C ||
      r == 0x00AD ||
      r == 0xFEFF ||
      (r >= 0x200B && r <= 0x200F) ||
      (r >= 0x202A && r <= 0x202E) ||
      (r >= 0x2066 && r <= 0x2069);
}
