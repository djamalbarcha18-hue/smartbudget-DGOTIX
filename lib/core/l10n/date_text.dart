import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart' show DateFormat;

/// A date as yyyy-MM-dd for display inside a sentence. It is wrapped in a
/// left-to-right isolate: next to Arabic letters the bidi algorithm would
/// otherwise treat the digits as Arabic numbers and show "21-09-2026".
String isoDate(DateTime d) =>
    '\u2066${DateFormat('yyyy-MM-dd').format(d)}\u2069';

/// A calendar day in the app language ("25 Oct 2026", «25 أكتوبر 2026»),
/// with Latin digits like every number in the app. English for a language
/// the date data doesn't cover.
String dayText(Locale locale, DateTime d) {
  final String name = locale.toString();
  final String use = DateFormat.localeExists(name)
      ? name
      : DateFormat.localeExists(locale.languageCode)
          ? locale.languageCode
          : 'en';
  return DateFormat.yMMMd(use).format(d);
}

/// A day of the month without the year ("25 Oct", «25 أكتوبر»), for chart
/// axes.
String shortDayText(Locale locale, DateTime d) {
  final String name = locale.toString();
  final String use = DateFormat.localeExists(name)
      ? name
      : DateFormat.localeExists(locale.languageCode)
          ? locale.languageCode
          : 'en';
  return DateFormat.MMMd(use).format(d);
}
