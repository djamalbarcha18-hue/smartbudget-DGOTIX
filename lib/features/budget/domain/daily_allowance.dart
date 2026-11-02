/// What is still safe to spend today to finish the month inside the budget.
///
/// A month's budget is a number you can't act on: "63% used" doesn't answer
/// "can I buy this?". Dividing what is left by the days that are left does,
/// and it corrects itself — overspend today and tomorrow's figure drops,
/// hold back and it rises.
///
/// Pure (no Flutter, no providers) so the arithmetic can be tested on its own.
library;

import 'package:smartbudget/core/money/money.dart';

abstract final class DailyAllowance {
  /// Days from [now] to the end of its month, today counted: the 28th of a
  /// 30-day month leaves 3 (28th, 29th, 30th). Never below 1.
  static int daysLeftInMonth(DateTime now) {
    // Day zero of the next month is the last day of this one.
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    final int left = lastDay - now.day + 1;
    return left < 1 ? 1 : left;
  }

  /// What is left of the month's budget; negative once it is overspent.
  static Money left(Money planned, Money spent) =>
      Money(planned.minorUnits - spent.minorUnits, planned.currencyCode);

  /// What can still be spent each remaining day (today included).
  ///
  /// Null without a budget, so the caller shows its "no budget" state rather
  /// than a figure. Zero — never a negative — once the budget is spent: the
  /// honest answer to "how much today?" is "nothing", and by how much it was
  /// overspent belongs in the caption, not in the headline figure.
  static Money? perDay(Money planned, Money spent, DateTime now) {
    if (planned.minorUnits <= 0) return null;
    final int remaining = planned.minorUnits - spent.minorUnits;
    if (remaining <= 0) return Money(0, planned.currencyCode);
    return Money(
        (remaining / daysLeftInMonth(now)).floor(), planned.currencyCode);
  }
}
