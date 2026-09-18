import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/reports/domain/report_period.dart';

void main() {
  test('monthly returns the single month', () {
    expect(ReportPeriods.monthsIn(ReportPeriod.monthly, 3), <int>[3]);
  });

  test('quarterly returns three months of the quarter', () {
    expect(ReportPeriods.monthsIn(ReportPeriod.quarterly, 1), <int>[1, 2, 3]);
    expect(ReportPeriods.monthsIn(ReportPeriod.quarterly, 4), <int>[10, 11, 12]);
  });

  test('half-yearly returns six months', () {
    expect(ReportPeriods.monthsIn(ReportPeriod.halfYearly, 1),
        <int>[1, 2, 3, 4, 5, 6]);
    expect(ReportPeriods.monthsIn(ReportPeriod.halfYearly, 2),
        <int>[7, 8, 9, 10, 11, 12]);
  });

  test('yearly returns all twelve months', () {
    expect(ReportPeriods.monthsIn(ReportPeriod.yearly, 1),
        <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
  });

  test('subCount matches each period', () {
    expect(ReportPeriods.subCount(ReportPeriod.monthly), 12);
    expect(ReportPeriods.subCount(ReportPeriod.quarterly), 4);
    expect(ReportPeriods.subCount(ReportPeriod.halfYearly), 2);
    expect(ReportPeriods.subCount(ReportPeriod.yearly), 1);
  });
}
