import 'dart:math';

import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

enum ChallengeType {
  noEatingOut7,
  noShopping7,
  noSpend3of7,
  logDaily7,
  save10Month,
  save20Month,
}

extension ChallengeRules on ChallengeType {
  bool get monthly =>
      this == ChallengeType.save10Month || this == ChallengeType.save20Month;

  /// Categories an expense must avoid (for "no …" challenges).
  Set<String> get avoided => switch (this) {
        ChallengeType.noEatingOut7 => const <String>{'المطاعم'},
        ChallengeType.noShopping7 => const <String>{'التسوق', 'الملابس'},
        _ => const <String>{},
      };

  /// Target: days, spend-free days, or a savings percentage.
  int get target => switch (this) {
        ChallengeType.noEatingOut7 => 7,
        ChallengeType.noShopping7 => 7,
        ChallengeType.noSpend3of7 => 3,
        ChallengeType.logDaily7 => 7,
        ChallengeType.save10Month => 10,
        ChallengeType.save20Month => 20,
      };

  /// Last day of a challenge started on [start]: 7 days, or the month's end.
  DateTime endFor(DateTime start) {
    final DateTime s = _day(start);
    return monthly
        ? DateTime(s.year, s.month + 1, 0)
        : s.add(const Duration(days: 6));
  }
}

class Challenge {
  const Challenge({
    required this.id,
    required this.type,
    required this.start,
    required this.createdAt,
  });

  final String id;
  final ChallengeType type;
  final DateTime start;
  final DateTime createdAt;

  DateTime get end => type.endFor(start);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        'createdAt': createdAt.toIso8601String(),
      };

  factory Challenge.fromJson(Map<String, dynamic> j) {
    final DateTime s = DateTime.tryParse('${j['start']}') ?? DateTime(2026);
    return Challenge(
      id: j['id'] as String,
      type: ChallengeType.values.firstWhere(
          (ChallengeType t) => t.name == j['type'],
          orElse: () => ChallengeType.logDaily7),
      start: _day(s),
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime(2026),
    );
  }
}

enum ChallengeStatus { active, won, lost }

class ChallengeProgress {
  const ChallengeProgress({
    required this.status,
    required this.current,
    required this.target,
    required this.daysLeft,
  });

  final ChallengeStatus status;

  /// Clean days, logged days, spend-free days or savings % so far.
  final int current;
  final int target;
  final int daysLeft;

  double get fraction => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

abstract final class ChallengeEngine {
  static ChallengeProgress evaluate(
    Challenge c,
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    final DateTime today = _day(now);
    final DateTime start = c.start;
    final DateTime end = c.end;
    final bool over = today.isAfter(end);
    final int daysLeft = over ? 0 : end.difference(today).inDays + 1;
    final DateTime last = over ? end : today;

    bool inWindow(Transaction t, DateTime until) {
      final DateTime d = _day(t.date);
      return !d.isBefore(start) && !d.isAfter(until);
    }

    int daysBetween(DateTime a, DateTime b) =>
        b.isBefore(a) ? 0 : b.difference(a).inDays + 1;

    ChallengeProgress p(ChallengeStatus s, int current) => ChallengeProgress(
        status: s, current: current, target: c.type.target, daysLeft: daysLeft);

    switch (c.type) {
      case ChallengeType.noEatingOut7:
      case ChallengeType.noShopping7:
        final bool broken = txns.any((Transaction t) =>
            t.type == TransactionType.expense &&
            c.type.avoided.contains(t.category) &&
            inWindow(t, last));
        final int clean = daysBetween(start, last);
        if (broken) return p(ChallengeStatus.lost, 0);
        return p(over ? ChallengeStatus.won : ChallengeStatus.active, clean);

      case ChallengeType.noSpend3of7:
        // Only finished days count; today may still see a purchase.
        final DateTime lastFull =
            over ? end : today.subtract(const Duration(days: 1));
        final Set<DateTime> spendDays = <DateTime>{
          for (final Transaction t in txns)
            if (t.type == TransactionType.expense && inWindow(t, lastFull))
              _day(t.date),
        };
        final int free = daysBetween(start, lastFull) - spendDays.length;
        if (free >= c.type.target) return p(ChallengeStatus.won, free);
        return p(over ? ChallengeStatus.lost : ChallengeStatus.active, max(0, free));

      case ChallengeType.logDaily7:
        final Set<DateTime> logged = <DateTime>{
          for (final Transaction t in txns)
            if (inWindow(t, last)) _day(t.date),
        };
        // A past day without any entry breaks it; today can still be logged.
        for (DateTime d = start; d.isBefore(last); d = d.add(const Duration(days: 1))) {
          if (!logged.contains(d)) return p(ChallengeStatus.lost, logged.length);
        }
        if (over && !logged.contains(end)) {
          return p(ChallengeStatus.lost, logged.length);
        }
        if (logged.length >= c.type.target) {
          return p(ChallengeStatus.won, logged.length);
        }
        return p(ChallengeStatus.active, logged.length);

      case ChallengeType.save10Month:
      case ChallengeType.save20Month:
        final FinanceSummary s = FinanceCalculator.summarize(
            FinanceCalculator.forMonth(txns, start.year, start.month),
            currency);
        final int pct = s.income.minorUnits <= 0
            ? 0
            : (s.savingsRate * 100).floor();
        if (!over) return p(ChallengeStatus.active, max(0, pct));
        return p(
            pct >= c.type.target ? ChallengeStatus.won : ChallengeStatus.lost,
            max(0, pct));
    }
  }
}

abstract final class Streaks {
  static Set<DateTime> _loggedDays(List<Transaction> txns) =>
      <DateTime>{for (final Transaction t in txns) _day(t.date)};

  /// Consecutive days with at least one entry, ending today — or yesterday,
  /// so the streak isn't shown as broken before today's entry.
  static int current(List<Transaction> txns, DateTime now) {
    final Set<DateTime> days = _loggedDays(txns);
    DateTime d = _day(now);
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    int n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static int longest(List<Transaction> txns) {
    final List<DateTime> days = _loggedDays(txns).toList()..sort();
    int best = 0;
    int run = 0;
    DateTime? prev;
    for (final DateTime d in days) {
      run = prev != null && d.difference(prev).inDays == 1 ? run + 1 : 1;
      best = max(best, run);
      prev = d;
    }
    return best;
  }

  /// Days this month (up to yesterday) without a single expense.
  static int noSpendDaysThisMonth(List<Transaction> txns, DateTime now) {
    final DateTime today = _day(now);
    final Set<DateTime> spend = <DateTime>{
      for (final Transaction t in txns)
        if (t.type == TransactionType.expense) _day(t.date),
    };
    int n = 0;
    for (int day = 1; day < today.day; day++) {
      if (!spend.contains(DateTime(today.year, today.month, day))) n++;
    }
    return n;
  }
}

enum BadgeKind {
  firstEntry,
  streak7,
  streak30,
  saver20,
  budgetKept,
  goalReached,
  challengeWon,
  seasonOnBudget,
  daretComplete,
}

abstract final class Badges {
  static Set<BadgeKind> earned({
    required List<Transaction> txns,
    required String currency,
    required DateTime now,
    List<BudgetTarget> budgets = const <BudgetTarget>[],
    List<Goal> goals = const <Goal>[],
    List<Challenge> challenges = const <Challenge>[],
    List<SeasonPlan> seasons = const <SeasonPlan>[],
    List<Daret> darets = const <Daret>[],
  }) {
    final Set<BadgeKind> out = <BadgeKind>{};
    if (txns.isNotEmpty) out.add(BadgeKind.firstEntry);
    final int best = Streaks.longest(txns);
    if (best >= 7) out.add(BadgeKind.streak7);
    if (best >= 30) out.add(BadgeKind.streak30);

    // Completed months only (the current one can still change).
    final Set<(int, int)> months = <(int, int)>{
      for (final Transaction t in txns)
        if (DateTime(t.date.year, t.date.month)
            .isBefore(DateTime(now.year, now.month)))
          (t.date.year, t.date.month),
    };
    for (final (int y, int m) in months) {
      final List<Transaction> month = FinanceCalculator.forMonth(txns, y, m);
      final FinanceSummary s = FinanceCalculator.summarize(month, currency);
      if (s.income.minorUnits > 0 && s.savingsRate >= 0.2) {
        out.add(BadgeKind.saver20);
      }
      final List<BudgetTarget> planned = budgets
          .where((BudgetTarget b) => b.year == y && b.month == m)
          .toList();
      if (planned.isNotEmpty) {
        final Map<String, int> actual = <String, int>{
          for (final CategoryTotal c in FinanceCalculator.categoryTotals(
              month, TransactionType.expense, currency))
            c.category: c.amount.minorUnits,
        };
        final bool kept = planned.every((BudgetTarget b) =>
            (actual[b.category] ?? 0) <= b.planned.minorUnits);
        if (kept) out.add(BadgeKind.budgetKept);
      }
    }

    if (goals.any((Goal g) => GoalCalculator.status(g) == GoalStatus.completed)) {
      out.add(BadgeKind.goalReached);
    }
    if (challenges.any((Challenge c) =>
        ChallengeEngine.evaluate(c, txns, currency, now).status ==
        ChallengeStatus.won)) {
      out.add(BadgeKind.challengeWon);
    }
    if (seasons.any((SeasonPlan p) =>
        SeasonMath.status(p, now) == SeasonStatus.ended &&
        p.budget.minorUnits > 0 &&
        SeasonMath.spent(p, txns, currency).minorUnits <= p.budget.minorUnits)) {
      out.add(BadgeKind.seasonOnBudget);
    }
    if (darets.any((Daret d) =>
        d.rounds > 0 &&
        DaretMath.finished(d, now) &&
        d.payoutReceived &&
        d.paidRounds.length >= d.rounds)) {
      out.add(BadgeKind.daretComplete);
    }
    return out;
  }
}
