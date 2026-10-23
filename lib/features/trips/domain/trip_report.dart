import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';

/// One category's part of a trip's spending.
class TripCategoryShare {
  const TripCategoryShare(this.category, this.amount, this.share);

  /// The category key (as stored on transactions).
  final String category;
  final Money amount;

  /// Of the trip's total, 0..1.
  final double share;
}

/// What a trip cost, worked out on the device from its tagged expenses: the
/// figures behind the home card, the summary and the share card.
class TripReport {
  TripReport._({
    required this.trip,
    required this.currency,
    required this.spent,
    required this.budget,
    required this.expenseCount,
    required this.categories,
    required this.daysCounted,
  });

  /// [currency] is the base currency; a trip with a budget is counted in
  /// the budget's currency.
  factory TripReport.of(Trip t, List<Transaction> txns, DateTime now,
      {required String currency}) {
    final Money? budget = t.plannedBudget;
    final String cur = budget?.currencyCode ?? currency;
    final Map<String, int> byCategory = <String, int>{};
    int total = 0;
    int count = 0;
    for (final Transaction x in TripMath.expensesOf(t, txns)) {
      count++;
      final int minor = x.inCurrency(cur)?.amount.minorUnits ?? 0;
      if (minor == 0) continue;
      total += minor;
      byCategory[x.category] = (byCategory[x.category] ?? 0) + minor;
    }
    final List<TripCategoryShare> cats = <TripCategoryShare>[
      for (final MapEntry<String, int> e in byCategory.entries)
        TripCategoryShare(
            e.key, Money(e.value, cur), total == 0 ? 0 : e.value / total),
    ]..sort((TripCategoryShare a, TripCategoryShare b) =>
        b.amount.minorUnits.compareTo(a.amount.minorUnits));
    return TripReport._(
      trip: t,
      currency: cur,
      spent: Money(total, cur),
      budget: budget,
      expenseCount: count,
      categories: cats,
      daysCounted: switch (TripMath.status(t, now)) {
        TripStatus.active => TripDays.dayNumber(t, now),
        _ => TripDays.total(t),
      },
    );
  }

  final Trip trip;
  final String currency;
  final Money spent;
  final Money? budget;
  final int expenseCount;

  /// Largest first.
  final List<TripCategoryShare> categories;

  /// Days the average is spread over: so far while under way, else all.
  final int daysCounted;

  bool get hasBudget => budget != null && budget!.minorUnits > 0;
  bool get hasExpenses => expenseCount > 0;

  Money get dailyAverage => Money(
      daysCounted == 0 ? 0 : (spent.minorUnits / daysCounted).round(),
      currency);

  /// Spent / budget (1.0 = all of it), or null without a budget.
  double? get usedRatio =>
      hasBudget ? spent.minorUnits / budget!.minorUnits : null;

  /// "Used 88% of the budget".
  int? get usedPct => usedRatio == null ? null : (usedRatio! * 100).round();

  /// Spent less than planned (the "you saved" badge).
  bool get underBudget => hasBudget && spent.minorUnits < budget!.minorUnits;
  bool get overBudget => hasBudget && spent.minorUnits > budget!.minorUnits;

  /// Left of the budget, as a share of it (at least 1 when under budget).
  int? get savedPct {
    if (!underBudget) return null;
    final int p = ((1 - usedRatio!) * 100).round();
    return p < 1 ? 1 : p;
  }

  int? get overPct => overBudget ? ((usedRatio! - 1) * 100).round() : null;

  /// Budget minus spent (negative when over), or null without a budget.
  Money? get difference => hasBudget ? budget! - spent : null;

  TripCategoryShare? get top => categories.isEmpty ? null : categories.first;

  /// The total split between the travellers, or null for one person.
  Money? get perPerson => trip.travelers > 1
      ? Money((spent.minorUnits / trip.travelers).round(), currency)
      : null;

  /// The daily average as a share of the budget ("8% of the budget a day").
  int? get dailyPctOfBudget => hasBudget
      ? (dailyAverage.minorUnits / budget!.minorUnits * 100).round()
      : null;
}

/// Counting a trip's days.
abstract final class TripDays {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int total(Trip t) => t.end.difference(t.start).inDays + 1;

  /// Day X of [total] (clamped to the trip).
  static int dayNumber(Trip t, DateTime now) {
    final int n = _day(now).difference(t.start).inDays + 1;
    return n.clamp(1, total(t));
  }

  /// Days left including today (while under way).
  static int leftIncludingToday(Trip t, DateTime now) =>
      (t.end.difference(_day(now)).inDays + 1).clamp(1, total(t));
}

/// The home card: which trip it shows and its figures.
abstract final class TripDashboard {
  /// An ended trip's summary stays on the home screen this long.
  static const int summaryDays = 14;

  /// A goal's monthly amount isn't shown with less time than this left.
  static const int minDaysForMonthly = 30;

  /// The trip closest in time: one under way (the latest to start), else the
  /// next one coming, else one that ended in the last [summaryDays] days.
  static Trip? pick(List<Trip> trips, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    Trip? active;
    Trip? next;
    Trip? ended;
    for (final Trip t in trips) {
      switch (TripMath.status(t, now)) {
        case TripStatus.active:
          if (active == null || t.start.isAfter(active.start)) active = t;
        case TripStatus.upcoming:
          if (next == null || t.start.isBefore(next.start)) next = t;
        case TripStatus.ended:
          final int since = today.difference(t.end).inDays;
          if (since <= summaryDays &&
              (ended == null || t.end.isAfter(ended.end))) {
            ended = t;
          }
      }
    }
    return active ?? next ?? ended;
  }

  /// What the trip's expenses on [day] add up to, in [currency].
  static Money spentOn(
      Trip t, List<Transaction> txns, DateTime day, String currency) {
    int minor = 0;
    for (final Transaction x in TripMath.expensesOf(t, txns)) {
      if (x.date.year == day.year &&
          x.date.month == day.month &&
          x.date.day == day.day) {
        minor += x.inCurrency(currency)?.amount.minorUnits ?? 0;
      }
    }
    return Money(minor, currency);
  }

  /// What can still be spent each day to stay within the budget (today
  /// included); zero once it is used up; null without a budget.
  static Money? dailyAvailable(TripReport r, DateTime now) {
    if (!r.hasBudget) return null;
    final int left = r.budget!.minorUnits - r.spent.minorUnits;
    if (left <= 0) return Money(0, r.currency);
    return Money(
        (left / TripDays.leftIncludingToday(r.trip, now)).floor(), r.currency);
  }

  /// To save each month to reach [goal] by the trip: (target − saved) ÷
  /// months left. Null when the goal is reached or the trip is too close.
  static Money? monthlyNeeded(Goal goal, Trip t, DateTime now) {
    final int left = goal.target.minorUnits - goal.saved.minorUnits;
    if (left <= 0) return null;
    final int days = TripMath.daysUntil(t, now);
    if (days < minDaysForMonthly) return null;
    final int months = days ~/ 30;
    return Money((left / months).ceil(), goal.target.currencyCode);
  }
}
