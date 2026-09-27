import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/seasons/domain/season_alerts.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

SeasonPlan plan({
  required DateTime start,
  required DateTime end,
  int budget = 100000,
  int saved = 0,
  SeasonKind kind = SeasonKind.ramadan,
}) =>
    SeasonPlan(
      id: 's1',
      kind: kind,
      start: start,
      end: end,
      budget: Money(budget, 'DZD'),
      saved: Money(saved, 'DZD'),
      createdAt: DateTime(2026),
    );

Transaction tx(DateTime d, int minor, {TransactionType type = TransactionType.expense, String cur = 'DZD'}) =>
    Transaction(
      id: 't${d.microsecondsSinceEpoch}$minor',
      date: d,
      type: type,
      category: 'الطعام',
      amount: Money(minor, cur),
      createdAt: d,
    );

void main() {
  group('SeasonCalendar', () {
    test('Ramadan runs from 1 Ramadan to the end of Eid al-Fitr', () {
      final SeasonWindow w = SeasonCalendar.window(SeasonKind.ramadan, 1448);
      final HijriDate s = HijriDate.fromGregorian(w.start);
      final HijriDate e = HijriDate.fromGregorian(w.end);
      expect((s.year, s.month, s.day), (1448, 9, 1));
      expect((e.year, e.month, e.day), (1448, 10, 3));
      // Ramadan 1448 falls in early 2027.
      expect(w.start.year, 2027);
      expect(w.start.month, 2);
    });

    test('next(): the upcoming occurrence, or the current one while it runs',
        () {
      final SeasonWindow r1448 = SeasonCalendar.window(SeasonKind.ramadan, 1448);
      final SeasonWindow r1449 = SeasonCalendar.window(SeasonKind.ramadan, 1449);
      expect(SeasonCalendar.next(SeasonKind.ramadan, DateTime(2026, 9, 27)),
          r1448);
      expect(
          SeasonCalendar.next(
              SeasonKind.ramadan, r1448.start.add(const Duration(days: 5))),
          r1448);
      expect(
          SeasonCalendar.next(
              SeasonKind.ramadan, r1448.end.add(const Duration(days: 1))),
          r1449);
      expect(SeasonCalendar.after(SeasonKind.ramadan, r1448), r1449);
    });

    test('previous(): the last finished occurrence', () {
      final SeasonWindow r1447 = SeasonCalendar.window(SeasonKind.ramadan, 1447);
      expect(SeasonCalendar.previous(SeasonKind.ramadan, DateTime(2026, 9, 27)),
          r1447);
    });

    test('Gregorian seasons roll over by year', () {
      expect(SeasonCalendar.next(SeasonKind.summer, DateTime(2026, 9, 27)),
          (start: DateTime(2027, 7, 1), end: DateTime(2027, 8, 31)));
      expect(SeasonCalendar.next(SeasonKind.schoolStart, DateTime(2026, 9, 27)),
          (start: DateTime(2026, 8, 20), end: DateTime(2026, 9, 30)));
    });
  });

  group('SeasonMath', () {
    final SeasonPlan p = plan(
        start: DateTime(2027, 2, 8), end: DateTime(2027, 3, 12), saved: 20000);

    test('status follows the window', () {
      expect(SeasonMath.status(p, DateTime(2027, 2, 7, 23)), SeasonStatus.upcoming);
      expect(SeasonMath.status(p, DateTime(2027, 2, 8)), SeasonStatus.active);
      expect(SeasonMath.status(p, DateTime(2027, 3, 12, 22)), SeasonStatus.active);
      expect(SeasonMath.status(p, DateTime(2027, 3, 13)), SeasonStatus.ended);
    });

    test('monthly saving spreads what is left over the months to go', () {
      // 134 days → 5 months; 80,000 left → 16,000 a month.
      expect(SeasonMath.daysUntil(p, DateTime(2026, 9, 27)), 134);
      expect(SeasonMath.monthlyNeeded(p, DateTime(2026, 9, 27)).minorUnits,
          16000);
      // Less than a month away still counts as one month.
      expect(SeasonMath.monthlyNeeded(p, DateTime(2027, 2, 1)).minorUnits,
          80000);
      expect(SeasonMath.remainingToSave(p.copyWith(saved: const Money(150000, 'DZD')))
          .minorUnits, 0);
    });

    test('spending counts expenses inside the window, base currency only', () {
      final List<Transaction> txns = <Transaction>[
        tx(DateTime(2027, 2, 7), 5000), // before
        tx(DateTime(2027, 2, 8, 20), 30000), // first day
        tx(DateTime(2027, 3, 12), 12000), // last day
        tx(DateTime(2027, 3, 13), 9000), // after
        tx(DateTime(2027, 2, 20), 70000, type: TransactionType.income),
        tx(DateTime(2027, 2, 20), 1000, cur: 'EUR'),
      ];
      expect(SeasonMath.spent(p, txns, 'DZD').minorUnits, 42000);
    });
  });

  group('SeasonAlerts', () {
    test('announces unfunded seasons within 45 days, urgent within 14', () {
      final DateTime now = DateTime(2027, 1, 1);
      final List<AppAlert> soon = SeasonAlerts.build(<SeasonPlan>[
        plan(start: DateTime(2027, 1, 10), end: DateTime(2027, 1, 20)),
      ], now);
      expect(soon.single.kind, AlertKind.seasonApproaching);
      expect(soon.single.severity, AlertSeverity.medium);
      expect(soon.single.subject, 'season:ramadan');
      expect(soon.single.amount.minorUnits, 100000);

      expect(
          SeasonAlerts.build(<SeasonPlan>[
            plan(start: DateTime(2027, 2, 10), end: DateTime(2027, 2, 20)),
          ], now).single.severity,
          AlertSeverity.info);
      // Too far, fully funded, or already running: nothing.
      expect(
          SeasonAlerts.build(<SeasonPlan>[
            plan(start: DateTime(2027, 4, 1), end: DateTime(2027, 4, 5)),
            plan(
                start: DateTime(2027, 1, 10),
                end: DateTime(2027, 1, 20),
                saved: 100000),
            plan(start: DateTime(2026, 12, 25), end: DateTime(2027, 1, 5)),
          ], now),
          isEmpty);
    });
  });

  test('season plans survive a backup round trip', () {
    final SeasonPlan p = plan(
            start: DateTime(2027, 2, 8),
            end: DateTime(2027, 3, 12),
            kind: SeasonKind.custom,
            saved: 500)
        .copyWith(name: 'عرس');
    final BackupData back = BackupCodec.decodeJson(BackupCodec.encodeJson(
        BackupData(
            exportedAt: DateTime(2026, 9, 27),
            baseCurrency: 'DZD',
            transactions: const <Transaction>[],
            budgets: const [],
            customIncome: const <String>[],
            customExpense: const <String>[],
            seasons: <SeasonPlan>[p])));
    final SeasonPlan r = back.seasons.single;
    expect(r.name, 'عرس');
    expect(r.kind, SeasonKind.custom);
    expect(r.start, DateTime(2027, 2, 8));
    expect(r.end, DateTime(2027, 3, 12));
    expect(r.saved.minorUnits, 500);
    expect(r.budget.currencyCode, 'DZD');
  });
}
