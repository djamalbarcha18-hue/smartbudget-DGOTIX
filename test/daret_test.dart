import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';

Daret daret({
  DaretFrequency f = DaretFrequency.monthly,
  DateTime? start,
  int me = 2,
  Set<int> paid = const <int>{},
  bool received = false,
}) =>
    Daret(
      id: 'd1',
      name: 'دارت العائلة',
      contribution: const Money(1000000, 'DZD'),
      frequency: f,
      start: start ?? DateTime(2026, 1, 31),
      members: const <String>['أمين', 'سارة', 'أنا', 'كريم', 'ليلى'],
      meIndex: me,
      paidRounds: paid,
      payoutReceived: received,
      createdAt: DateTime(2026),
    );

void main() {
  test('the pot is everyone\'s contribution', () {
    expect(daret().pot.minorUnits, 5000000);
  });

  test('monthly rounds keep the day, clamped to short months', () {
    final Daret d = daret();
    expect(DaretMath.roundDate(d, 0), DateTime(2026, 1, 31));
    expect(DaretMath.roundDate(d, 1), DateTime(2026, 2, 28));
    expect(DaretMath.roundDate(d, 2), DateTime(2026, 3, 31));
    expect(DaretMath.roundDate(d, 11), DateTime(2026, 12, 31));
    expect(DaretMath.roundDate(d, 12), DateTime(2027, 1, 31));
    expect(DaretMath.myTurn(d), DateTime(2026, 3, 31));
  });

  test('weekly rounds step by 7 days', () {
    final Daret d = daret(f: DaretFrequency.weekly, start: DateTime(2026, 9, 1));
    expect(DaretMath.roundDate(d, 3), DateTime(2026, 9, 22));
    expect(DaretMath.lastRound(d), DateTime(2026, 9, 29));
  });

  test('rounds due, next round, overdue and finished', () {
    final Daret d = daret(paid: <int>{0});
    final DateTime mid = DateTime(2026, 3, 10);
    expect(DaretMath.roundsDue(d, mid), 2);
    expect(DaretMath.nextRound(d, mid), 2);
    expect(DaretMath.overdue(d, mid), <int>[1]);
    expect(DaretMath.nextUnpaid(d), 1);
    // A round due today isn't overdue yet.
    expect(DaretMath.overdue(d, DateTime(2026, 2, 28)), isEmpty);
    expect(DaretMath.finished(d, DateTime(2026, 5, 31)), isFalse);
    expect(DaretMath.finished(d, DateTime(2026, 6, 1)), isTrue);
    expect(DaretMath.nextRound(d, DateTime(2026, 6, 1)), isNull);
  });

  test('paid so far counts only the user\'s marked rounds', () {
    expect(DaretMath.paid(daret(paid: <int>{0, 1, 3})).minorUnits, 3000000);
  });

  group('alerts', () {
    test('a payment within 3 days, the payout within 7', () {
      final List<AppAlert> a =
          DaretMath.alerts(<Daret>[daret(paid: <int>{0, 1})], DateTime(2026, 3, 28));
      expect(a.map((AppAlert x) => x.kind),
          <AlertKind>[AlertKind.daretPayment, AlertKind.daretPayout]);
      expect(a.first.amount.minorUnits, 1000000);
      expect(a.first.date, DateTime(2026, 3, 31));
      expect(a.last.amount.minorUnits, 5000000);
    });

    test('nothing when far away, already paid, or already collected', () {
      expect(
          DaretMath.alerts(<Daret>[daret(paid: <int>{0, 1})], DateTime(2026, 3, 10)),
          isEmpty);
      expect(
          DaretMath.alerts(<Daret>[
            daret(paid: <int>{0, 1, 2}, received: true)
          ], DateTime(2026, 3, 28)),
          isEmpty);
    });
  });

  test('JSON round trip', () {
    final Daret d = daret(paid: <int>{2, 0}, received: true);
    final Daret r = Daret.fromJson(d.toJson());
    expect(r.members, d.members);
    expect(r.meIndex, 2);
    expect(r.paidRounds, <int>{0, 2});
    expect(r.payoutReceived, isTrue);
    expect(r.start, DateTime(2026, 1, 31));
    expect(r.contribution.minorUnits, 1000000);
    expect(r.frequency, DaretFrequency.monthly);
  });
}
