import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/transactions/domain/entry_date.dart';

/// A new entry must land in the month the dashboard shows (the reported
/// "data moves to another month" bug), not in today's month.
void main() {
  final DateTime now = DateTime(2026, 11, 15, 9, 30);

  test('the current month keeps the exact current time', () {
    expect(entryDateForMonth(now, 2026, 11), now);
  });

  test('a past month gets the same day in that month', () {
    expect(entryDateForMonth(now, 2026, 10), DateTime(2026, 10, 15, 9, 30));
  });

  test('a past year lands in that year', () {
    expect(entryDateForMonth(now, 2025, 11), DateTime(2025, 11, 15, 9, 30));
  });

  test('a shorter month is clamped to its last day', () {
    final DateTime d31 = DateTime(2026, 3, 31, 20, 5);
    expect(entryDateForMonth(d31, 2026, 2), DateTime(2026, 2, 28, 20, 5));
    expect(entryDateForMonth(d31, 2028, 2), DateTime(2028, 2, 29, 20, 5));
    expect(entryDateForMonth(d31, 2026, 4), DateTime(2026, 4, 30, 20, 5));
  });

  test('the result always falls inside the requested month', () {
    for (int day = 1; day <= 31; day++) {
      final DateTime n = DateTime(2026, 1, day, 12);
      for (int m = 1; m <= 12; m++) {
        final DateTime d = entryDateForMonth(n, 2026, m);
        expect(d.year, 2026);
        expect(d.month, m, reason: 'day $day into month $m');
      }
    }
  });
}
