/// When to remind the user to back up. Pure, so it is unit-testable.
///
/// The app keeps financial data in the browser; clearing site data or
/// switching devices loses it unless a backup exists. The reminder appears
/// once there is data and no backup for [BackupReminder.everyDays] days —
/// counted from the last backup, or from the oldest entry when the user has
/// never backed up (so brand-new users aren't nagged on day one).
library;

abstract final class BackupReminder {
  static const int everyDays = 14;
  static const int snoozeDays = 7;

  static bool isDue({
    required DateTime now,
    required DateTime? lastBackup,
    required DateTime? oldestData,
    DateTime? snoozedUntil,
  }) {
    if (oldestData == null) return false; // nothing to lose yet
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
    final DateTime since = lastBackup ?? oldestData;
    return now.difference(since).inDays >= everyDays;
  }

  /// Whole days since the last backup (null when never backed up).
  static int? daysSince(DateTime? lastBackup, DateTime now) =>
      lastBackup == null ? null : now.difference(lastBackup).inDays;
}
