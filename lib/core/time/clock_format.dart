/// Formats a UTC offset as `UTC+01:00` / `UTC−05:30` (Latin digits, LTR).
String formatUtcOffset(Duration offset) {
  final String sign = offset.isNegative ? '−' : '+';
  final int minutes = offset.inMinutes.abs();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'UTC$sign${two(minutes ~/ 60)}:${two(minutes % 60)}';
}

/// Splits a clock drift into its largest meaningful unit for display.
({int days, int hours, int minutes, int seconds}) splitDrift(Duration d) {
  final Duration a = d.abs();
  return (
    days: a.inDays,
    hours: a.inHours % 24,
    minutes: a.inMinutes % 60,
    seconds: a.inSeconds % 60,
  );
}
