import 'package:intl/intl.dart' show DateFormat;

/// A date as yyyy-MM-dd for display inside a sentence. It is wrapped in a
/// left-to-right isolate: next to Arabic letters the bidi algorithm would
/// otherwise treat the digits as Arabic numbers and show "21-09-2026".
String isoDate(DateTime d) =>
    '\u2066${DateFormat('yyyy-MM-dd').format(d)}\u2069';
