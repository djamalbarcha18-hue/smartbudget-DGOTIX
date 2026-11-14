/// The date a new entry starts on when the screen shows [year]/[month].
///
/// The current month gives [now] unchanged. Any other month gives the same
/// day of the month (the last day when that month is shorter) at the current
/// time of day, so the entry lands in the month the user is looking at
/// instead of silently going to today's month.
DateTime entryDateForMonth(DateTime now, int year, int month) {
  if (now.year == year && now.month == month) return now;
  final int lastDay = DateTime(year, month + 1, 0).day;
  final int day = now.day <= lastDay ? now.day : lastDay;
  return DateTime(year, month, day, now.hour, now.minute);
}
