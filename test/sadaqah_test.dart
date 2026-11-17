import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/islamic_features.dart';
import 'package:smartbudget/features/sadaqah/domain/sadaqah_commitment.dart';

void main() {
  // Tuesday 17 November 2026, 12:00.
  final DateTime now = DateTime(2026, 11, 17, 12);

  SadaqahCommitment weekly({Set<String> paid = const <String>{}}) =>
      SadaqahCommitment(
        id: 'a',
        createdAt: now,
        weekday: DateTime.friday,
        paid: paid,
      );

  test('weekly: due on the chosen weekday of each week', () {
    final List<DateTime> next = weekly().upcoming(now, 3);
    expect(next, <DateTime>[
      DateTime(2026, 11, 20, 10),
      DateTime(2026, 11, 27, 10),
      DateTime(2026, 12, 4, 10),
    ]);
  });

  test('"done" skips only that period', () {
    final SadaqahCommitment done = weekly().markedPaid(now);
    expect(done.isPaidFor(now), isTrue);
    expect(done.upcoming(now, 2).first, DateTime(2026, 11, 27, 10));
    expect(done.unmarkedPaid(now).isPaidFor(now), isFalse);
  });

  test('monthly: the chosen day, next month once it has passed', () {
    final SadaqahCommitment m = SadaqahCommitment(
      id: 'b',
      createdAt: now,
      frequency: SadaqahFrequency.monthly,
      dayOfMonth: 1,
    );
    expect(m.upcoming(now, 2),
        <DateTime>[DateTime(2026, 12, 1, 10), DateTime(2027, 1, 1, 10)]);
    expect(m.periodOf(now), 'M2026-11');
  });

  test('ISO weeks across the new year', () {
    expect(SadaqahCommitment.isoWeek(DateTime(2026, 11, 17)), (2026, 47));
    expect(SadaqahCommitment.isoWeek(DateTime(2027, 1, 1)), (2026, 53));
  });

  test('saved and read back the same', () {
    final SadaqahCommitment c = weekly(paid: <String>{'W2026-47'}).copyWith(
        note: 'x', amount: const Money(500, 'EUR'), recordAsExpense: false);
    final SadaqahCommitment? back = SadaqahCommitment.fromJson(c.toJson());
    expect(back!.toJson(), c.toJson());
    expect(SadaqahCommitment.fromJson('nope'), isNull);
  });

  test('only commitments asking for a reminder are scheduled', () {
    final List<DateTime> plan = SadaqahSchedule.plan(<SadaqahCommitment>[
      weekly(),
      weekly().copyWith(remind: false),
    ], now);
    expect(plan, hasLength(SadaqahSchedule.perCommitment));
  });

  test('Islamic features are suggested for Muslim-majority languages', () {
    expect(IslamicFeatures.suggestedFor('ar'), isTrue);
    expect(IslamicFeatures.suggestedFor('ur'), isTrue);
    expect(IslamicFeatures.suggestedFor('en'), isFalse);
    expect(IslamicFeatures.suggestedFor('fr'), isFalse);
  });
}
