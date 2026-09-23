/// Smart salary split — suggests how to divide a month's income across budget
/// categories, based on the user's own recent spending.
///
/// Order of priority (a "pay yourself first" plan that stays realistic):
///   1. NEEDS keep their recent average (rent, bills, food… are not cut).
///   2. SAVINGS get the largest of: 10% of income, what dated goals need per
///      month, or what the user already saves — capped at what is left.
///   3. WANTS keep their averages if they fit; otherwise they are scaled down
///      proportionally. Anything left over goes to savings.
/// With no spending history it falls back to the public 50/30/20 rule and
/// says so. Nothing is invented: every amount is an average of real data or a
/// share of the income the user confirmed. Pure Dart, integer money only.
library;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

enum SplitBucket { needs, wants, savings }

/// Where the suggestion came from.
enum SplitBasis {
  /// Averages of the user's own recent spending.
  history,

  /// No history yet: the generic 50/30/20 rule.
  rule,
}

/// Which bucket each expense category belongs to. Categories not listed —
/// including the user's custom ones — count as wants.
abstract final class SplitClassifier {
  static const String savingsCategory = 'الادخار والاستثمار';

  static const Set<String> needs = <String>{
    'السكن',
    'الفواتير',
    'الاتصالات والإنترنت',
    'الطعام',
    'النقل',
    'الوقود',
    'الصحة',
    'التعليم',
    'الأطفال والعائلة',
    'الأقساط والقروض',
    'التأمين',
    'الضرائب والرسوم',
    'الصيانة والإصلاح',
    'زكاة',
  };

  static const Set<String> savings = <String>{savingsCategory, 'الطوارئ'};

  static SplitBucket bucketOf(String category) {
    if (savings.contains(category)) return SplitBucket.savings;
    if (needs.contains(category)) return SplitBucket.needs;
    return SplitBucket.wants;
  }
}

class SplitLine {
  const SplitLine({
    required this.category,
    required this.bucket,
    required this.average,
    required this.suggested,
  });

  final String category;
  final SplitBucket bucket;

  /// Recent monthly average actually spent (zero for the rule-based line).
  final Money average;

  /// Suggested monthly budget for this category.
  final Money suggested;
}

class SalarySplit {
  const SalarySplit({
    required this.income,
    required this.basis,
    required this.monthsOfHistory,
    required this.lines,
    required this.needs,
    required this.wants,
    required this.savings,
    required this.shortfall,
    required this.trimmed,
    required this.goalsMonthly,
    required this.goalsUncovered,
  });

  final Money income;
  final SplitBasis basis;
  final int monthsOfHistory;

  /// Category lines to apply to the budget: needs, then wants, then savings.
  final List<SplitLine> lines;

  /// Bucket totals of the suggestion.
  final Money needs;
  final Money wants;
  final Money savings;

  /// How much recent needs exceed the income (zero when they fit).
  final Money shortfall;

  /// How much wants were reduced below their recent averages to fit.
  final Money trimmed;

  /// What goals with a deadline need per month to finish on time.
  final Money goalsMonthly;

  /// The part of [goalsMonthly] the income could not cover.
  final Money goalsUncovered;

  bool get isDeficit => shortfall.minorUnits > 0;
  bool get hasIncome => income.minorUnits > 0;

  /// Share of the income, 0..1 (0 when there is no income).
  double shareOf(Money m) =>
      income.minorUnits <= 0 ? 0 : m.minorUnits / income.minorUnits;
}

abstract final class SalarySplitEngine {
  /// Full calendar months of history used (before the target month).
  static const int historyMonths = 3;

  /// Minimum savings rate when history allows it.
  static const double minSavingsRate = 0.10;

  static const double ruleNeeds = 0.50;
  static const double ruleWants = 0.30;

  /// The [historyMonths] calendar months before ([year], [month]), newest first.
  static List<(int, int)> historyWindow(int year, int month) {
    final List<(int, int)> out = <(int, int)>[];
    int y = year;
    int m = month;
    for (int i = 0; i < historyMonths; i++) {
      m -= 1;
      if (m == 0) {
        m = 12;
        y -= 1;
      }
      out.add((y, m));
    }
    return out;
  }

  static bool _inWindow(DateTime d, List<(int, int)> window) {
    for (final (int, int) w in window) {
      if (d.year == w.$1 && d.month == w.$2) return true;
    }
    return false;
  }

  /// A sensible starting income: what was earned in the target month if any,
  /// otherwise the average monthly income over the history window. Only
  /// transactions in [currency] count, like every other summary in the app.
  static Money defaultIncome({
    required List<Transaction> transactions,
    required int year,
    required int month,
    required String currency,
  }) {
    int thisMonth = 0;
    final Map<(int, int), int> byMonth = <(int, int), int>{};
    final List<(int, int)> window = historyWindow(year, month);
    for (final Transaction t in transactions) {
      if (!t.isIncome || t.amount.currencyCode != currency) continue;
      if (t.date.year == year && t.date.month == month) {
        thisMonth += t.amount.minorUnits;
      } else if (_inWindow(t.date, window)) {
        final (int, int) key = (t.date.year, t.date.month);
        byMonth[key] = (byMonth[key] ?? 0) + t.amount.minorUnits;
      }
    }
    if (thisMonth > 0) return Money(thisMonth, currency);
    if (byMonth.isEmpty) return Money.zero(currency);
    final int total = byMonth.values.fold(0, (int a, int b) => a + b);
    return Money((total / byMonth.length).round(), currency);
  }

  /// What goals with a future deadline need per month (in [currency]).
  static Money goalsMonthly(List<Goal> goals, String currency,
      {DateTime? now}) {
    int total = 0;
    for (final Goal g in goals) {
      if (g.target.currencyCode != currency) continue;
      if (g.deadline == null) continue; // no deadline ⇒ no monthly obligation
      final int? months = GoalCalculator.monthsRemaining(g, now: now);
      if (months == null || months <= 0) continue;
      total += GoalCalculator.monthlyInstallment(g, now: now).minorUnits;
    }
    return Money(total, currency);
  }

  static SalarySplit compute({
    required Money income,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required int year,
    required int month,
    DateTime? now,
  }) {
    final String cur = income.currencyCode;
    final Money zero = Money.zero(cur);
    final Money goalsNeed = goalsMonthly(goals, cur, now: now);

    // Expense history in the window, in the income's currency.
    final List<(int, int)> window = historyWindow(year, month);
    final Map<String, int> totals = <String, int>{};
    final Set<(int, int)> monthsSeen = <(int, int)>{};
    for (final Transaction t in transactions) {
      if (!t.isExpense || t.amount.currencyCode != cur) continue;
      if (!_inWindow(t.date, window)) continue;
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.minorUnits;
      monthsSeen.add((t.date.year, t.date.month));
    }
    final int n = monthsSeen.length;
    final int inc = income.minorUnits;

    if (inc <= 0) {
      return SalarySplit(
        income: income,
        basis: n == 0 ? SplitBasis.rule : SplitBasis.history,
        monthsOfHistory: n,
        lines: const <SplitLine>[],
        needs: zero,
        wants: zero,
        savings: zero,
        shortfall: zero,
        trimmed: zero,
        goalsMonthly: goalsNeed,
        goalsUncovered: goalsNeed,
      );
    }

    // ---- No history: the 50/30/20 rule (only savings maps to a category).
    if (n == 0) {
      final int needs = (inc * ruleNeeds).floor();
      final int wants = (inc * ruleWants).floor();
      final int save = inc - needs - wants;
      return SalarySplit(
        income: income,
        basis: SplitBasis.rule,
        monthsOfHistory: 0,
        lines: <SplitLine>[
          SplitLine(
            category: SplitClassifier.savingsCategory,
            bucket: SplitBucket.savings,
            average: zero,
            suggested: Money(save, cur),
          ),
        ],
        needs: Money(needs, cur),
        wants: Money(wants, cur),
        savings: Money(save, cur),
        shortfall: zero,
        trimmed: zero,
        goalsMonthly: goalsNeed,
        goalsUncovered: Money(
            goalsNeed.minorUnits > save ? goalsNeed.minorUnits - save : 0, cur),
      );
    }

    // ---- Monthly averages per category, by bucket.
    final Map<String, int> needAvg = <String, int>{};
    final Map<String, int> wantAvg = <String, int>{};
    int savedAvg = 0;
    totals.forEach((String cat, int total) {
      final int avg = (total / n).round();
      if (avg <= 0) return;
      switch (SplitClassifier.bucketOf(cat)) {
        case SplitBucket.needs:
          needAvg[cat] = avg;
        case SplitBucket.wants:
          wantAvg[cat] = avg;
        case SplitBucket.savings:
          savedAvg += avg;
      }
    });
    final int needsTotal = needAvg.values.fold(0, (int a, int b) => a + b);
    final int wantsTotal = wantAvg.values.fold(0, (int a, int b) => a + b);

    List<SplitLine> linesFor(
            Map<String, int> suggested, Map<String, int> avg, SplitBucket b) =>
        (suggested.keys.toList()
              ..sort((String x, String y) => avg[y]!.compareTo(avg[x]!)))
            .map((String c) => SplitLine(
                  category: c,
                  bucket: b,
                  average: Money(avg[c]!, cur),
                  suggested: Money(suggested[c]!, cur),
                ))
            .toList();

    // ---- Needs alone exceed the income: show the gap honestly.
    if (needsTotal >= inc) {
      return SalarySplit(
        income: income,
        basis: SplitBasis.history,
        monthsOfHistory: n,
        lines: linesFor(needAvg, needAvg, SplitBucket.needs),
        needs: Money(needsTotal, cur),
        wants: zero,
        savings: zero,
        shortfall: Money(needsTotal - inc, cur),
        trimmed: Money(wantsTotal, cur),
        goalsMonthly: goalsNeed,
        goalsUncovered: goalsNeed,
      );
    }

    // ---- Savings next, then wants.
    final int afterNeeds = inc - needsTotal;
    int saveTarget = (inc * minSavingsRate).round();
    if (goalsNeed.minorUnits > saveTarget) saveTarget = goalsNeed.minorUnits;
    if (savedAvg > saveTarget) saveTarget = savedAvg;
    final int saveBase = saveTarget < afterNeeds ? saveTarget : afterNeeds;
    final int forWants = afterNeeds - saveBase;

    final Map<String, int> wantSug = <String, int>{};
    int wantsGiven;
    if (wantsTotal <= forWants) {
      wantSug.addAll(wantAvg);
      wantsGiven = wantsTotal;
    } else {
      final double k = wantsTotal == 0 ? 0 : forWants / wantsTotal;
      wantsGiven = 0;
      wantAvg.forEach((String c, int avg) {
        final int v = (avg * k).floor();
        wantSug[c] = v;
        wantsGiven += v;
      });
    }
    // Everything not given to needs/wants is saved (surplus + rounding dust),
    // so the plan always adds up to exactly the income.
    final int save = inc - needsTotal - wantsGiven;

    return SalarySplit(
      income: income,
      basis: SplitBasis.history,
      monthsOfHistory: n,
      lines: <SplitLine>[
        ...linesFor(needAvg, needAvg, SplitBucket.needs),
        ...linesFor(wantSug, wantAvg, SplitBucket.wants),
        SplitLine(
          category: SplitClassifier.savingsCategory,
          bucket: SplitBucket.savings,
          average: Money(savedAvg, cur),
          suggested: Money(save, cur),
        ),
      ],
      needs: Money(needsTotal, cur),
      wants: Money(wantsGiven, cur),
      savings: Money(save, cur),
      shortfall: zero,
      trimmed: Money(wantsTotal - wantsGiven, cur),
      goalsMonthly: goalsNeed,
      goalsUncovered: Money(
          goalsNeed.minorUnits > save ? goalsNeed.minorUnits - save : 0, cur),
    );
  }
}
