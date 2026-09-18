/// Reporting period type (mirrors the SmartBudget V1 analysis periods).
enum ReportPeriod { monthly, quarterly, halfYearly, yearly }

/// Helpers to map a period + sub-index to calendar months (1..12).
abstract final class ReportPeriods {
  /// How many sub-selections a period has (e.g. 12 months, 4 quarters).
  static int subCount(ReportPeriod p) => switch (p) {
        ReportPeriod.monthly => 12,
        ReportPeriod.quarterly => 4,
        ReportPeriod.halfYearly => 2,
        ReportPeriod.yearly => 1,
      };

  /// The calendar months (1..12) covered by [p] and 1-based [sub].
  static List<int> monthsIn(ReportPeriod p, int sub) {
    switch (p) {
      case ReportPeriod.yearly:
        return List<int>.generate(12, (int i) => i + 1);
      case ReportPeriod.halfYearly:
        final int start = (sub == 2) ? 7 : 1;
        return List<int>.generate(6, (int i) => start + i);
      case ReportPeriod.quarterly:
        final int q = sub.clamp(1, 4);
        final int start = (q - 1) * 3 + 1;
        return <int>[start, start + 1, start + 2];
      case ReportPeriod.monthly:
        return <int>[sub.clamp(1, 12)];
    }
  }

  /// A sensible default sub for "now" within a period.
  static int defaultSub(ReportPeriod p, DateTime now) => switch (p) {
        ReportPeriod.monthly => now.month,
        ReportPeriod.quarterly => ((now.month - 1) ~/ 3) + 1,
        ReportPeriod.halfYearly => now.month <= 6 ? 1 : 2,
        ReportPeriod.yearly => 1,
      };
}
