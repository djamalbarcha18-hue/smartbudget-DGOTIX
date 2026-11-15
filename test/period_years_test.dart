import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/transactions/domain/period_years.dart';

void main() {
  group('selectableYears', () {
    test('no data: this year and the next nine', () {
      expect(selectableYears(2027, const <int>[], 2027),
          <int>[for (int y = 2027; y <= 2036; y++) y]);
    });

    test('last year stays reachable after New Year', () {
      final List<int> ys = selectableYears(2027, <int>[2026, 2027], 2027);
      expect(ys.first, 2026);
      expect(ys, contains(2027));
    });

    test('goes back to the oldest year with data', () {
      expect(selectableYears(2027, <int>[2023, 2026], 2027).first, 2023);
    });

    test('always holds the year the screens are filtered on', () {
      expect(selectableYears(2027, const <int>[], 2020), contains(2020));
      expect(selectableYears(2027, const <int>[], 2040), contains(2040));
    });
  });

  group('followCalendar', () {
    final DateTime oct31 = DateTime(2026, 10, 31, 23, 59);
    final DateTime nov1 = DateTime(2026, 11, 1, 0, 1);

    test('the current month moves on with the calendar', () {
      expect(followCalendar((year: 2026, month: 10), oct31, nov1),
          (year: 2026, month: 11));
    });

    test('across New Year the year moves too', () {
      expect(
          followCalendar((year: 2026, month: 12), DateTime(2026, 12, 31, 23),
              DateTime(2027, 1, 1, 0, 5)),
          (year: 2027, month: 1));
    });

    test('a month the user picked stays', () {
      expect(followCalendar((year: 2026, month: 7), oct31, nov1), isNull);
    });

    test('nothing happens within the same month', () {
      expect(
          followCalendar((year: 2026, month: 10), DateTime(2026, 10, 3),
              DateTime(2026, 10, 4)),
          isNull);
    });
  });
}
