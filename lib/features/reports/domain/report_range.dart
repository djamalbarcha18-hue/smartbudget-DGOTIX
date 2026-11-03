/// The calendar span a report covers, and the span before it.
///
/// Reports are built from a period and a 1-based sub-index (month 1..12,
/// quarter 1..4, half 1..2, year). Comparing a period with the one before it
/// means crossing a year boundary for January, Q1 and the first half, so the
/// range carries its own year rather than borrowing the screen's.
///
/// Pure: no Flutter, no providers. See test/report_range_test.dart.
library;

import 'package:flutter/foundation.dart';

import 'package:smartbudget/features/reports/domain/report_period.dart';

@immutable
class ReportRange {
  const ReportRange({
    required this.period,
    required this.year,
    required this.sub,
  });

  final ReportPeriod period;
  final int year;

  /// 1-based within the year: the month, the quarter, the half, or 1.
  final int sub;

  /// The calendar months this range covers, as (year, month) pairs.
  ///
  /// A range never straddles a year, so every pair carries [year]; the type
  /// keeps callers from having to remember that.
  List<({int year, int month})> get months => <({int year, int month})>[
        for (final int m in ReportPeriods.monthsIn(period, sub))
          (year: year, month: m),
      ];

  /// Whether [date] falls inside this range.
  bool contains(DateTime date) {
    if (date.year != year) return false;
    return ReportPeriods.monthsIn(period, sub).contains(date.month);
  }

  /// The range of the same length immediately before this one.
  ///
  /// January's is December of the year before; Q1's is Q4; the first half's
  /// is the second half of the year before; a year's is the year before.
  ReportRange get previous {
    final int count = ReportPeriods.subCount(period);
    if (sub > 1) {
      return ReportRange(period: period, year: year, sub: sub - 1);
    }
    return ReportRange(period: period, year: year - 1, sub: count);
  }

  @override
  bool operator ==(Object other) =>
      other is ReportRange &&
      other.period == period &&
      other.year == year &&
      other.sub == sub;

  @override
  int get hashCode => Object.hash(period, year, sub);

  @override
  String toString() => 'ReportRange(${period.name}, $year, $sub)';
}
