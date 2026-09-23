import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/backup/domain/backup_reminder.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 20);
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  test('no data yet: never remind', () {
    expect(
        BackupReminder.isDue(now: now, lastBackup: null, oldestData: null),
        isFalse);
  });

  test('new user is not nagged on day one', () {
    expect(
        BackupReminder.isDue(
            now: now, lastBackup: null, oldestData: daysAgo(3)),
        isFalse);
  });

  test('never backed up and data is 14+ days old: remind', () {
    expect(
        BackupReminder.isDue(
            now: now, lastBackup: null, oldestData: daysAgo(14)),
        isTrue);
  });

  test('recent backup: no reminder; stale backup: remind', () {
    expect(
        BackupReminder.isDue(
            now: now, lastBackup: daysAgo(5), oldestData: daysAgo(200)),
        isFalse);
    expect(
        BackupReminder.isDue(
            now: now, lastBackup: daysAgo(15), oldestData: daysAgo(200)),
        isTrue);
  });

  test('snooze hides it until it expires', () {
    expect(
        BackupReminder.isDue(
            now: now,
            lastBackup: daysAgo(30),
            oldestData: daysAgo(200),
            snoozedUntil: now.add(const Duration(days: 2))),
        isFalse);
    expect(
        BackupReminder.isDue(
            now: now,
            lastBackup: daysAgo(30),
            oldestData: daysAgo(200),
            snoozedUntil: daysAgo(1)),
        isTrue);
  });

  test('daysSince', () {
    expect(BackupReminder.daysSince(null, now), isNull);
    expect(BackupReminder.daysSince(daysAgo(3), now), 3);
  });
}
