import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/zakat/domain/hawl.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

void main() {
  group('HijriDate', () {
    test('Gregorian -> Hijri -> Gregorian round-trips', () {
      for (final DateTime g in <DateTime>[
        DateTime(2000, 1, 1),
        DateTime(2015, 6, 18),
        DateTime(2024, 7, 7),
        DateTime(2026, 9, 20),
        DateTime(2030, 12, 31),
      ]) {
        final DateTime back = HijriDate.fromGregorian(g).toGregorian();
        expect(back.year, g.year, reason: '$g');
        expect(back.month, g.month, reason: '$g');
        expect(back.day, g.day, reason: '$g');
      }
    });

    test('modern date lands in a plausible Hijri year', () {
      final HijriDate h = HijriDate.fromGregorian(DateTime(2024, 7, 7));
      expect(h.year, anyOf(1445, 1446));
      expect(h.month, inInclusiveRange(1, 12));
      expect(h.day, inInclusiveRange(1, 30));
    });
  });

  group('HawlStatus', () {
    test('one Hijri year is ~354 days (353..356)', () {
      final DateTime start = DateTime(2025, 1, 10);
      final HawlStatus s = HawlStatus.compute(start, start);
      final int len = s.due.difference(start).inDays;
      expect(len, inInclusiveRange(353, 356));
      expect(s.complete, isFalse);
      expect(s.daysRemaining, inInclusiveRange(353, 356));
    });

    test('not complete before due, complete on/after due', () {
      final DateTime start = DateTime(2025, 3, 1);
      final HawlStatus mid = HawlStatus.compute(start, start.add(const Duration(days: 100)));
      expect(mid.complete, isFalse);
      expect(mid.daysRemaining, greaterThan(0));

      final HawlStatus done =
          HawlStatus.compute(start, start.add(const Duration(days: 400)));
      expect(done.complete, isTrue);
      expect(done.daysRemaining, 0);
    });
  });
}
