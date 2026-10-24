import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';

/// One item's part of a trip's spending.
class TripItemShare {
  const TripItemShare(this.item, this.amount, this.share);

  /// Flights, stay… (read from the expenses' categories).
  final TripItem item;
  final Money amount;

  /// Of the trip's total, 0..1.
  final double share;
}

/// An item's share of the budget against what was spent on it.
class TripItemPlan {
  const TripItemPlan(this.item, this.percent, this.planned, this.spent);

  final TripItem item;

  /// Of the budget (0 for "other", which isn't planned).
  final int percent;
  final Money planned;
  final Money spent;

  /// Over its share by more than this part of it is flagged; a little over
  /// (a few euros) only shows as "slightly over".
  static const double tolerance = 0.05;

  bool get over => spent.minorUnits > planned.minorUnits;

  /// Over by more than [tolerance] of its share (always, with nothing
  /// planned).
  bool get clearlyOver =>
      spent.minorUnits > planned.minorUnits * (1 + tolerance);

  /// Planned minus spent (negative when over).
  Money get left => planned - spent;

  /// Spent / planned (above 1 when over); 0 with nothing planned.
  double get ratio =>
      planned.minorUnits == 0 ? 0 : spent.minorUnits / planned.minorUnits;
}

/// A smart hint: the item furthest over its share, and the one with the
/// most left to cover it, if any.
class TripItemTip {
  const TripItemTip(this.over, this.overBy, this.spare, this.spareLeft);

  final TripItem over;
  final Money overBy;
  final TripItem? spare;
  final Money? spareLeft;
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
    required this.plan,
    required this.daysCounted,
  });

  /// [currency] is the base currency; a trip with a budget is counted in
  /// the budget's currency.
  factory TripReport.of(Trip t, List<Transaction> txns, DateTime now,
      {required String currency}) {
    final Money? budget = t.plannedBudget;
    final String cur = budget?.currencyCode ?? currency;
    final Map<TripItem, int> byItem = <TripItem, int>{};
    int total = 0;
    int count = 0;
    for (final Transaction x in TripMath.expensesOf(t, txns)) {
      count++;
      final int minor = x.inCurrency(cur)?.amount.minorUnits ?? 0;
      if (minor == 0) continue;
      total += minor;
      final TripItem item = TripItems.of(x.category, t.kind);
      byItem[item] = (byItem[item] ?? 0) + minor;
    }
    final List<TripItemShare> cats = <TripItemShare>[
      for (final MapEntry<TripItem, int> e in byItem.entries)
        TripItemShare(
            e.key, Money(e.value, cur), total == 0 ? 0 : e.value / total),
    ]..sort((TripItemShare a, TripItemShare b) =>
        b.amount.minorUnits.compareTo(a.amount.minorUnits));
    // The budget split between the items, in whole minor units that add up
    // to the budget; "other" only once something is spent on it.
    final List<TripItemPlan> plan = <TripItemPlan>[];
    if (budget != null && budget.minorUnits > 0) {
      final Map<TripItem, int> split = TripItems.splitOf(t);
      final List<TripItem> items = TripItems.plannedFor(t.kind);
      final List<int> parts = TripItems.shares(budget.minorUnits, <double>[
        for (final TripItem i in items) (split[i] ?? 0).toDouble(),
      ]);
      for (int k = 0; k < items.length; k++) {
        final TripItem i = items[k];
        plan.add(TripItemPlan(i, split[i] ?? 0, Money(parts[k], cur),
            Money(byItem[i] ?? 0, cur)));
      }
      final int other = byItem[TripItem.other] ?? 0;
      if (other > 0) {
        plan.add(TripItemPlan(
            TripItem.other, 0, Money(0, cur), Money(other, cur)));
      }
    }
    return TripReport._(
      trip: t,
      currency: cur,
      spent: Money(total, cur),
      budget: budget,
      expenseCount: count,
      categories: cats,
      plan: plan,
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

  /// By item, largest first.
  final List<TripItemShare> categories;

  /// With a budget: each item's share of it against what was spent, in the
  /// planned order (empty without a budget).
  final List<TripItemPlan> plan;

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

  TripItemShare? get top => categories.isEmpty ? null : categories.first;

  /// The planned item furthest over its share, and the one with the most
  /// left to cover it; null when every item is within its share (or only
  /// slightly over, see [TripItemPlan.tolerance]).
  TripItemTip? get tip {
    TripItemPlan? over;
    TripItemPlan? spare;
    for (final TripItemPlan p in plan) {
      if (p.item == TripItem.other) continue;
      if (p.clearlyOver &&
          (over == null || p.left.minorUnits < over.left.minorUnits)) {
        over = p;
      }
      if (!p.over &&
          p.left.minorUnits > 0 &&
          (spare == null || p.left.minorUnits > spare.left.minorUnits)) {
        spare = p;
      }
    }
    if (over == null) return null;
    return TripItemTip(over.item, over.spent - over.planned, spare?.item,
        spare?.left);
  }

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
  /// next one coming, else one that ended in the last [summaryDays] days and
  /// hasn't been shared yet (sharing it closes its card).
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
              t.sharedAt == null &&
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

/// What the user usually has left at the end of a month, and what that could
/// put aside before a trip: a hint next to the trip budget, never imposed.
class TripBudgetAdvice {
  const TripBudgetAdvice({
    required this.monthlySurplus,
    required this.monthsCounted,
    required this.monthsLeft,
  });

  /// Complete months looked back at (those with any transaction).
  static const int lookBack = 6;

  /// Average of income − expenses over [monthsCounted] recent complete
  /// months (zero or less: no surplus).
  final Money monthlySurplus;
  final int monthsCounted;

  /// Whole months until the trip starts.
  final int monthsLeft;

  String get _currency => monthlySurplus.currencyCode;

  bool get hasSurplus => monthlySurplus.minorUnits > 0;

  /// The surplus of every month left, or null when there is none to count.
  Money? get canSave => hasSurplus && monthsLeft > 0
      ? Money(monthlySurplus.minorUnits * monthsLeft, _currency)
      : null;

  /// [canSave] in round figures (whole units; tens from 100 up).
  Money? get suggestedBudget {
    final Money? m = canSave;
    if (m == null) return null;
    final int per = m.currency.minorPerUnit;
    int units = m.minorUnits ~/ per;
    if (units >= 100) units -= units % 10;
    return units <= 0 ? null : Money(units * per, _currency);
  }

  /// What [budget] needs each month until the trip; null within a month.
  Money? neededPerMonth(Money budget) => monthsLeft > 0
      ? Money((budget.minorUnits / monthsLeft).ceil(), budget.currencyCode)
      : null;

  /// Whether [budget] fits in the usual surplus (null: can't tell).
  bool? fits(Money budget) {
    final Money? need = neededPerMonth(budget);
    if (need == null || budget.currencyCode != _currency) return null;
    return need.minorUnits <= monthlySurplus.minorUnits;
  }

  /// From the last [lookBack] complete months before [now] that have any
  /// transaction, in [currency]; null when there is none yet.
  static TripBudgetAdvice? of(List<Transaction> txns, String currency,
      DateTime now, DateTime tripStart) {
    int total = 0;
    int counted = 0;
    for (int back = 1; back <= lookBack; back++) {
      final DateTime month = DateTime(now.year, now.month - back);
      final List<Transaction> inMonth =
          FinanceCalculator.forMonth(txns, month.year, month.month);
      final FinanceSummary s = FinanceCalculator.summarize(inMonth, currency);
      if (s.count == 0) continue;
      total += s.net.minorUnits;
      counted++;
    }
    if (counted == 0) return null;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = tripStart.difference(today).inDays;
    return TripBudgetAdvice(
      monthlySurplus: Money((total / counted).round(), currency),
      monthsCounted: counted,
      monthsLeft: days < 30 ? 0 : days ~/ 30,
    );
  }
}
