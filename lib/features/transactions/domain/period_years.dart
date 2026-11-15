/// The years a period picker offers: from the oldest year with data (never
/// later than [nowYear]) to nine years ahead, plus [selected] if it falls
/// outside, so the picker always shows the year the screens are filtered on.
List<int> selectableYears(int nowYear, Iterable<int> dataYears, int selected) {
  int first = nowYear;
  for (final int y in dataYears) {
    if (y < first) first = y;
  }
  final int last = nowYear + 9;
  if (selected < first) first = selected;
  final List<int> years = <int>[for (int y = first; y <= last; y++) y];
  if (selected > last) years.add(selected);
  return years;
}

/// The month the screens should show after the clock moved from [was] to
/// [now]. The view follows the calendar only while it shows the month that
/// was current ([shown] == [was]); a month the user picked stays.
({int year, int month})? followCalendar(
    ({int year, int month}) shown, DateTime was, DateTime now) {
  final bool onCurrent = shown.year == was.year && shown.month == was.month;
  final bool moved = was.year != now.year || was.month != now.month;
  if (!onCurrent || !moved) return null;
  return (year: now.year, month: now.month);
}
