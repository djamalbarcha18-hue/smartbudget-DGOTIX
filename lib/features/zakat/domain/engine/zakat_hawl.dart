/// The hawl (one lunar year) between a start date and the zakat date.
library;

import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

class ZakatHawl {
  const ZakatHawl({
    required this.start,
    required this.end,
    required this.adjustDays,
  });

  /// One Hijri year after [start] (the tabular calendar), moved by
  /// [adjustDays] (-1, 0 or +1) when the announced month start differed from
  /// the calculated one. A start on the 30th of a month that has 29 days a
  /// year later ends on that month's last day (it used to spill a day over).
  factory ZakatHawl.from(DateTime start, {int adjustDays = 0}) {
    if (adjustDays < -1 || adjustDays > 1) {
      throw ArgumentError.value(adjustDays, 'adjustDays', 'must be -1, 0 or 1');
    }
    final DateTime s = DateTime(start.year, start.month, start.day);
    final HijriDate h = HijriDate.fromGregorian(s);
    final DateTime monthStart = HijriDate(h.year + 1, h.month, 1).toGregorian();
    final DateTime nextMonthStart = (h.month == 12
            ? HijriDate(h.year + 2, 1, 1)
            : HijriDate(h.year + 1, h.month + 1, 1))
        .toGregorian();
    final int length = _days(monthStart, nextMonthStart);
    final int day = h.day <= length ? h.day : length;
    final DateTime end = _addDays(monthStart, day - 1 + adjustDays);
    return ZakatHawl(start: s, end: end, adjustDays: adjustDays);
  }

  final DateTime start;
  final DateTime end;
  final int adjustDays;

  /// Whether the hawl is complete on [date] (its end day included).
  bool completeOn(DateTime date) =>
      !DateTime(date.year, date.month, date.day).isBefore(end);

  static int _days(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  static DateTime _addDays(DateTime d, int n) {
    final DateTime u = DateTime.utc(d.year, d.month, d.day).add(Duration(days: n));
    return DateTime(u.year, u.month, u.day);
  }
}
