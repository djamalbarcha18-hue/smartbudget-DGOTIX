import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/analytics/domain/kpi_math.dart';

void main() {
  group('KpiChange.of', () {
    test('normal increase computes a positive percentage', () {
      final KpiChange c =
          KpiChange.of(current: 1250, previous: 1000, hasPrevious: true);
      expect(c.comparable, isTrue);
      expect(c.direction, KpiDirection.up);
      expect(c.absolute, 250);
      expect(c.percentage, closeTo(0.25, 1e-9));
    });

    test('decrease is negative and directed down', () {
      final KpiChange c =
          KpiChange.of(current: 800, previous: 1000, hasPrevious: true);
      expect(c.direction, KpiDirection.down);
      expect(c.percentage, closeTo(-0.20, 1e-9));
    });

    test('previous == 0 → not comparable (no misleading %)', () {
      final KpiChange c =
          KpiChange.of(current: 500, previous: 0, hasPrevious: true);
      expect(c.comparable, isFalse);
      expect(c.percentage, isNull);
      expect(c.direction, KpiDirection.up);
    });

    test('no prior data → not comparable', () {
      final KpiChange c =
          KpiChange.of(current: 500, previous: 0, hasPrevious: false);
      expect(c.comparable, isFalse);
      expect(c.percentage, isNull);
    });

    test('negative previous uses magnitude for the percentage', () {
      // e.g. net went from −200 (loss) to +100 (profit): +300 over |−200|.
      final KpiChange c =
          KpiChange.of(current: 100, previous: -200, hasPrevious: true);
      expect(c.direction, KpiDirection.up);
      expect(c.percentage, closeTo(1.5, 1e-9));
    });
  });

  group('semantic tone', () {
    test('income up is good; expense up is bad', () {
      final KpiChange up =
          KpiChange.of(current: 120, previous: 100, hasPrevious: true);
      expect(up.sentiment(positiveWhenUp: true), KpiSentiment.good);
      expect(up.sentiment(positiveWhenUp: false), KpiSentiment.bad);
    });

    test('expense down is good; income down is bad', () {
      final KpiChange down =
          KpiChange.of(current: 80, previous: 100, hasPrevious: true);
      expect(down.sentiment(positiveWhenUp: false), KpiSentiment.good);
      expect(down.sentiment(positiveWhenUp: true), KpiSentiment.bad);
    });

    test('flat is neutral regardless of direction meaning', () {
      final KpiChange flat =
          KpiChange.of(current: 100, previous: 100, hasPrevious: true);
      expect(flat.sentiment(positiveWhenUp: true), KpiSentiment.neutral);
      expect(flat.sentiment(positiveWhenUp: false), KpiSentiment.neutral);
    });
  });
}
