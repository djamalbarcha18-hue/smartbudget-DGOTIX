import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

/// Hawl (حول) status: whether a full lunar (Hijri) year has elapsed since the
/// wealth first reached nisab. Zakat is due only when BOTH nisab is met AND the
/// hawl is complete.
class HawlStatus {
  const HawlStatus({
    required this.start,
    required this.startHijri,
    required this.due,
    required this.dueHijri,
    required this.complete,
    required this.daysRemaining,
  });

  final DateTime start;
  final HijriDate startHijri;
  final DateTime due;
  final HijriDate dueHijri;
  final bool complete;

  /// Days until the hawl completes (0 once complete).
  final int daysRemaining;

  /// Computes the hawl from its Gregorian [start] date and [now]. Completion is
  /// exactly one Hijri year after the start.
  static HawlStatus compute(DateTime start, DateTime now) {
    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final HijriDate startHijri = HijriDate.fromGregorian(startDay);
    final HijriDate dueHijri = startHijri.addYears(1);
    final DateTime due = dueHijri.toGregorian();
    final bool complete = !today.isBefore(due);
    final int remaining = complete ? 0 : due.difference(today).inDays;
    return HawlStatus(
      start: startDay,
      startHijri: startHijri,
      due: due,
      dueHijri: dueHijri,
      complete: complete,
      daysRemaining: remaining,
    );
  }
}
