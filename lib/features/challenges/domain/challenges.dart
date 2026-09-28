import 'dart:math';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The one challenge: days without "side" spending — the small extras that
/// add up (eating out, shopping, entertainment…). Essentials such as rent,
/// groceries, bills or transport never break it.
abstract final class SideFree {
  /// What counts as side spending unless the user picks otherwise.
  static const Set<String> defaultCategories = <String>{
    'المطاعم',
    'التسوق',
    'الملابس',
    'الترفيه',
  };

  /// Categories offered as "side" (plus the user's own custom ones).
  static const List<String> suggested = <String>[
    'المطاعم',
    'التسوق',
    'الملابس',
    'الترفيه',
    'الاشتراكات',
    'السفر',
    'الرياضة واللياقة',
    'الأثاث والمنزل',
    'البرمجيات والأدوات الرقمية',
    'أخرى',
  ];

  static const List<int> durations = <int>[3, 7, 14, 30];

  /// Slip days forgiven: one per full week (3 days → none, 7 → 1, 30 → 4).
  static int allowedSlips(int days) => days ~/ 7;

  /// History used to estimate what the user usually spends on extras.
  static const int baselineDays = 28;

  static bool isSide(Transaction t, Set<String> categories) =>
      t.type == TransactionType.expense && categories.contains(t.category);
}

class Challenge {
  const Challenge({
    required this.id,
    required this.days,
    required this.categories,
    required this.start,
    required this.createdAt,
  });

  final String id;

  /// Length: one of [SideFree.durations].
  final int days;

  /// What counts as side spending for this run (kept with the challenge so
  /// later changes don't rewrite past results).
  final Set<String> categories;
  final DateTime start;
  final DateTime createdAt;

  DateTime get end => _day(start).add(Duration(days: days - 1));
  int get allowedSlips => SideFree.allowedSlips(days);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': 'sideFree',
        'days': days,
        'categories': categories.toList(),
        'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        'createdAt': createdAt.toIso8601String(),
      };

  factory Challenge.fromJson(Map<String, dynamic> j) {
    final DateTime s = DateTime.tryParse('${j['start']}') ?? DateTime(2026);
    final List<dynamic>? cats = j['categories'] as List<dynamic>?;
    // Challenges saved before the side-free redesign carry a 'type'; they
    // become the nearest side-free challenge so history keeps a result.
    final (int, Set<String>) legacy = switch (j['type']) {
      'noEatingOut7' => (7, const <String>{'المطاعم'}),
      'noShopping7' => (7, const <String>{'التسوق', 'الملابس'}),
      'noSpend3of7' => (3, SideFree.defaultCategories),
      _ => (7, SideFree.defaultCategories),
    };
    final int days = (j['days'] as num?)?.toInt() ?? legacy.$1;
    return Challenge(
      id: j['id'] as String,
      days: days.clamp(1, 366),
      categories:
          cats == null ? legacy.$2 : <String>{for (final dynamic c in cats) '$c'},
      start: _day(s),
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime(2026),
    );
  }
}

enum ChallengeStatus { active, won, lost }

/// One day of a challenge, as shown on its strip.
enum DayMark {
  /// Finished without side spending.
  clean,

  /// Had side spending.
  slip,

  /// Today, nothing on the extras (yet).
  today,

  /// Still ahead.
  upcoming,
}

class ChallengeProgress {
  const ChallengeProgress({
    required this.status,
    required this.marks,
    required this.clean,
    required this.slips,
    required this.allowedSlips,
    required this.daysLeft,
    required this.sideSpent,
    this.saved,
  });

  final ChallengeStatus status;
  final List<DayMark> marks;

  /// Finished days without side spending.
  final int clean;
  final int slips;
  final int allowedSlips;
  final int daysLeft;

  /// Side spending during the challenge so far (base currency).
  final Money sideSpent;

  /// Estimated money kept: the usual daily side spending (from the weeks
  /// before) times the finished days, minus what was spent. Null without
  /// history, on the first day, or when nothing was saved.
  final Money? saved;

  int get days => marks.length;
  int get slipsLeft => max(0, allowedSlips - slips);

  /// Days that can still end clean (today included).
  int get cleanSoFarOrToday =>
      clean + marks.where((DayMark m) => m == DayMark.today).length;

  double get fraction => days == 0 ? 0 : (clean / days).clamp(0.0, 1.0);
}

abstract final class ChallengeEngine {
  static ChallengeProgress evaluate(
    Challenge c,
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    final DateTime today = _day(now);
    final DateTime start = _day(c.start);
    final DateTime end = c.end;
    final bool over = today.isAfter(end);
    final DateTime last = over ? end : today;

    final Set<DateTime> slipDays = <DateTime>{};
    int spent = 0;
    int before = 0;
    bool history = false;
    final DateTime baselineFrom =
        start.subtract(const Duration(days: SideFree.baselineDays));
    for (final Transaction t in txns) {
      final DateTime d = _day(t.date);
      if (d.isBefore(start)) history = true;
      if (!SideFree.isSide(t, c.categories)) continue;
      final int minor = t.inCurrency(currency)?.amount.minorUnits ?? 0;
      if (!d.isBefore(start) && !d.isAfter(last)) {
        slipDays.add(d);
        spent += minor;
      } else if (d.isBefore(start) && !d.isBefore(baselineFrom)) {
        before += minor;
      }
    }

    final List<DayMark> marks = <DayMark>[
      for (int i = 0; i < c.days; i++)
        () {
          final DateTime d = start.add(Duration(days: i));
          if (d.isAfter(today)) return DayMark.upcoming;
          if (slipDays.contains(d)) return DayMark.slip;
          if (d == today && !over) return DayMark.today;
          return DayMark.clean;
        }(),
    ];
    final int clean = marks.where((DayMark m) => m == DayMark.clean).length;
    final int slips = marks.where((DayMark m) => m == DayMark.slip).length;

    final ChallengeStatus status = slips > c.allowedSlips
        ? ChallengeStatus.lost
        : over
            ? ChallengeStatus.won
            : ChallengeStatus.active;

    Money? saved;
    // Finished days only: today's extras may still come.
    final int elapsed =
        over ? c.days : today.difference(start).inDays;
    if (history && before > 0 && elapsed > 0) {
      final int kept =
          (before / SideFree.baselineDays * elapsed).round() - spent;
      if (kept > 0) saved = Money(kept, currency);
    }

    return ChallengeProgress(
      status: status,
      marks: marks,
      clean: clean,
      slips: slips,
      allowedSlips: c.allowedSlips,
      daysLeft: over ? 0 : end.difference(today).inDays + 1,
      sideSpent: Money(spent, currency),
      saved: saved,
    );
  }
}

/// Runs of days without side spending, counted only from the first recorded
/// transaction (days before the user started tracking prove nothing) and
/// only over finished days (today can still change).
abstract final class SideFreeStreaks {
  static (DateTime, Set<DateTime>)? _scan(
      List<Transaction> txns, Set<String> categories) {
    if (txns.isEmpty) return null;
    DateTime first = _day(txns.first.date);
    final Set<DateTime> slips = <DateTime>{};
    for (final Transaction t in txns) {
      final DateTime d = _day(t.date);
      if (d.isBefore(first)) first = d;
      if (SideFree.isSide(t, categories)) slips.add(d);
    }
    return (first, slips);
  }

  /// Consecutive clean days ending yesterday.
  static int current(
      List<Transaction> txns, Set<String> categories, DateTime now) {
    final (DateTime, Set<DateTime>)? s = _scan(txns, categories);
    if (s == null) return 0;
    int n = 0;
    DateTime d = _day(now).subtract(const Duration(days: 1));
    while (!d.isBefore(s.$1) && !s.$2.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static int longest(
      List<Transaction> txns, Set<String> categories, DateTime now) {
    final (DateTime, Set<DateTime>)? s = _scan(txns, categories);
    if (s == null) return 0;
    final DateTime yesterday =
        _day(now).subtract(const Duration(days: 1));
    int best = 0;
    int run = 0;
    for (DateTime d = s.$1;
        !d.isAfter(yesterday);
        d = d.add(const Duration(days: 1))) {
      run = s.$2.contains(d) ? 0 : run + 1;
      best = max(best, run);
    }
    return best;
  }

  /// Clean days so far this month (finished days only).
  static int thisMonth(
      List<Transaction> txns, Set<String> categories, DateTime now) {
    final (DateTime, Set<DateTime>)? s = _scan(txns, categories);
    if (s == null) return 0;
    final DateTime today = _day(now);
    int n = 0;
    for (int day = 1; day < today.day; day++) {
      final DateTime d = DateTime(today.year, today.month, day);
      if (!d.isBefore(s.$1) && !s.$2.contains(d)) n++;
    }
    return n;
  }
}

enum BadgeKind {
  firstEntry,
  cleanWeek,
  cleanMonth,
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
    Set<String> sideCategories = SideFree.defaultCategories,
    List<BudgetTarget> budgets = const <BudgetTarget>[],
    List<Goal> goals = const <Goal>[],
    List<Challenge> challenges = const <Challenge>[],
    List<SeasonPlan> seasons = const <SeasonPlan>[],
    List<Daret> darets = const <Daret>[],
  }) {
    final Set<BadgeKind> out = <BadgeKind>{};
    if (txns.isNotEmpty) out.add(BadgeKind.firstEntry);
    final int best = SideFreeStreaks.longest(txns, sideCategories, now);
    if (best >= 7) out.add(BadgeKind.cleanWeek);
    if (best >= 30) out.add(BadgeKind.cleanMonth);

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
