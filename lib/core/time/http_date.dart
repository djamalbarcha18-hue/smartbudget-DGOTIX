/// Parses an HTTP `Date` header (RFC 7231 IMF-fixdate, e.g.
/// `Sun, 27 Sep 2026 10:15:30 GMT`) into a UTC [DateTime], or null.
///
/// `dart:io`'s HttpDate isn't available on the web, hence this small parser.
DateTime? parseHttpDate(String? value) {
  if (value == null) return null;
  final RegExpMatch? m = RegExp(
          r'^\s*\w{3},\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+GMT\s*$')
      .firstMatch(value);
  if (m == null) return null;
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final int month = months.indexOf(m[2]!) + 1;
  if (month == 0) return null;
  return DateTime.utc(int.parse(m[3]!), month, int.parse(m[1]!),
      int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
}
