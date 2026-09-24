/// The financial context handed to DGOTIX AI: a compact, factual summary built
/// only from figures the app already computed. Pure (no Flutter, no IO).
///
/// Privacy: it carries amounts, app category names and counts only — never
/// transaction descriptions, notes, goal/debt names or any personal detail.
library;

/// One spending category with its amount this month (already formatted).
class AiCategoryLine {
  const AiCategoryLine(this.category, this.amount, this.share);
  final String category;
  final String amount;

  /// 0..1 of the month's spending.
  final double share;
}

/// Everything the snapshot may mention; null / empty means "unknown" and the
/// line is simply left out (nothing is ever guessed).
class AiSnapshotInput {
  const AiSnapshotInput({
    required this.currency,
    required this.today,
    required this.hasData,
    this.monthLabel = '',
    this.monthIncome,
    this.monthExpense,
    this.monthNet,
    this.prevMonthIncome,
    this.prevMonthExpense,
    this.yearIncome,
    this.yearExpense,
    this.yearNet,
    this.yearSavingsRate,
    this.topCategories = const <AiCategoryLine>[],
    this.budgetPlanned,
    this.budgetSpent,
    this.budgetUsed,
    this.goalsCount = 0,
    this.goalsSaved,
    this.goalsTarget,
    this.goalsProgress,
    this.owedToMe,
    this.owedByMe,
    this.recurringDueCount = 0,
    this.recurringDueTotal,
    this.zakatDue,
    this.healthScore,
    this.healthStatus,
    this.healthConfidence,
  });

  final String currency;
  final String today; // yyyy-MM-dd
  final bool hasData;
  final String monthLabel; // yyyy-MM
  final String? monthIncome;
  final String? monthExpense;
  final String? monthNet;
  final String? prevMonthIncome;
  final String? prevMonthExpense;
  final String? yearIncome;
  final String? yearExpense;
  final String? yearNet;
  final double? yearSavingsRate;
  final List<AiCategoryLine> topCategories;
  final String? budgetPlanned;
  final String? budgetSpent;
  final double? budgetUsed;
  final int goalsCount;
  final String? goalsSaved;
  final String? goalsTarget;
  final double? goalsProgress;
  final String? owedToMe;
  final String? owedByMe;
  final int recurringDueCount;
  final String? recurringDueTotal;
  final String? zakatDue; // null = not due / unknown
  final int? healthScore;
  final String? healthStatus;
  final int? healthConfidence;
}

abstract final class AiSnapshot {
  static String _pct(double v) => '${(v * 100).round()}%';

  static String build(AiSnapshotInput i) {
    final StringBuffer b = StringBuffer()
      ..writeln('Base currency: ${i.currency}. Today: ${i.today}.');
    if (!i.hasData) {
      b.writeln('No transactions recorded yet.');
      return b.toString().trim();
    }
    if (i.monthIncome != null) {
      b.writeln('This month (${i.monthLabel}): income ${i.monthIncome}, '
          'expenses ${i.monthExpense}, net ${i.monthNet}.');
    }
    if (i.prevMonthIncome != null) {
      b.writeln('Last month: income ${i.prevMonthIncome}, '
          'expenses ${i.prevMonthExpense}.');
    }
    if (i.yearIncome != null) {
      b.write('Year to date: income ${i.yearIncome}, expenses '
          '${i.yearExpense}, net ${i.yearNet}');
      if (i.yearSavingsRate != null) {
        b.write(', savings rate ${_pct(i.yearSavingsRate!)}');
      }
      b.writeln('.');
    }
    if (i.topCategories.isNotEmpty) {
      b.writeln('Top spending this month: ${i.topCategories.map(
          (AiCategoryLine c) => '${c.category} ${c.amount} (${_pct(c.share)})').join('; ')}.');
    }
    if (i.budgetPlanned != null) {
      b.writeln('Budget this month: planned ${i.budgetPlanned}, spent '
          '${i.budgetSpent} (${_pct(i.budgetUsed ?? 0)} used).');
    } else {
      b.writeln('Budget this month: not set.');
    }
    if (i.goalsCount > 0) {
      b.writeln('Savings goals: ${i.goalsCount}, saved ${i.goalsSaved} of '
          '${i.goalsTarget} (${_pct(i.goalsProgress ?? 0)}).');
    }
    if (i.owedToMe != null || i.owedByMe != null) {
      b.writeln('Debts: owed to me ${i.owedToMe ?? '0'}, I owe '
          '${i.owedByMe ?? '0'}.');
    }
    if (i.recurringDueCount > 0) {
      b.writeln('Recurring payments due in the next 7 days: '
          '${i.recurringDueCount}, expenses total ${i.recurringDueTotal}.');
    }
    b.writeln(i.zakatDue != null
        ? 'Zakat: due, ${i.zakatDue}.'
        : 'Zakat: not due (or nisab not reached).');
    if (i.healthScore != null) {
      b.writeln('Financial health: ${i.healthScore}/100 (${i.healthStatus}), '
          'data confidence ${i.healthConfidence}%.');
    }
    return b.toString().trim();
  }
}
