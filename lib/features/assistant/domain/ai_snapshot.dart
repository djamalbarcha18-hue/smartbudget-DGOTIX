/// The financial context handed to DGOTIX AI: a compact, factual summary built
/// only from figures the app already computed. Pure (no Flutter, no IO).
///
/// Privacy: it carries amounts, dates, app category names and counts only —
/// never transaction descriptions, notes, or the names the user gave to
/// wallets, goals, debts, seasons or daret groups (those are numbered).
library;

/// One spending category with its amount this month (already formatted).
class AiCategoryLine {
  const AiCategoryLine(this.category, this.amount, this.share);
  final String category;
  final String amount;

  /// 0..1 of the month's spending.
  final double share;
}

/// One month of history: totals and the expense categories.
class AiMonthLine {
  const AiMonthLine({
    required this.label,
    required this.income,
    required this.expense,
    required this.net,
    this.categories = const <AiCategoryLine>[],
    this.current = false,
  });

  final String label; // yyyy-MM
  final String income;
  final String expense;
  final String net;
  final List<AiCategoryLine> categories;

  /// The month in progress (its figures are partial).
  final bool current;
}

/// A category's budget this month and what was spent in it.
class AiBudgetLine {
  const AiBudgetLine(this.category, this.planned, this.spent, this.used);
  final String category;
  final String planned;
  final String spent;
  final double used; // spent / planned
}

/// A wallet's balance in its own currency, named by kind (never by the
/// user's label).
class AiWalletLine {
  const AiWalletLine(this.kind, this.balance);
  final String kind; // e.g. "general", "cash #2"
  final String balance;
}

class AiGoalLine {
  const AiGoalLine({
    required this.saved,
    required this.target,
    required this.progress,
    this.deadline,
  });
  final String saved;
  final String target;
  final double progress;
  final String? deadline; // yyyy-MM-dd
}

class AiRecurringLine {
  const AiRecurringLine({
    required this.income,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.next,
  });
  final bool income;
  final String category;
  final String amount;
  final String frequency; // weekly | monthly | yearly
  final String next; // yyyy-MM-dd
}

class AiSeasonLine {
  const AiSeasonLine({
    required this.kind,
    required this.start,
    required this.end,
    required this.status,
    required this.budget,
    required this.setAside,
    this.spent,
  });
  final String kind; // ramadan, eidAdha, schoolStart, summer, custom
  final String start;
  final String end;
  final String status; // upcoming | active | ended
  final String budget;
  final String setAside;
  final String? spent; // once started
}

class AiDaretLine {
  const AiDaretLine({
    required this.contribution,
    required this.frequency,
    required this.rounds,
    required this.paidRounds,
    required this.myTurn,
    required this.payoutReceived,
    this.nextPayment,
  });
  final String contribution;
  final String frequency; // weekly | monthly
  final int rounds;
  final int paidRounds;
  final String myTurn; // yyyy-MM-dd
  final bool payoutReceived;
  final String? nextPayment; // yyyy-MM-dd of the earliest unpaid round
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
    this.incomeCategories = const <AiCategoryLine>[],
    this.history = const <AiMonthLine>[],
    this.categoryBudgets = const <AiBudgetLine>[],
    this.wallets = const <AiWalletLine>[],
    this.goals = const <AiGoalLine>[],
    this.recurring = const <AiRecurringLine>[],
    this.seasons = const <AiSeasonLine>[],
    this.darets = const <AiDaretLine>[],
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

  /// Income per category this month.
  final List<AiCategoryLine> incomeCategories;

  /// Up to 12 months, oldest first, the current month last.
  final List<AiMonthLine> history;
  final List<AiBudgetLine> categoryBudgets;
  final List<AiWalletLine> wallets;
  final List<AiGoalLine> goals;
  final List<AiRecurringLine> recurring;
  final List<AiSeasonLine> seasons;
  final List<AiDaretLine> darets;
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
    _details(b, i);
    return b.toString().trim();
  }

  static String _cats(List<AiCategoryLine> cats) => cats
      .map((AiCategoryLine c) => '${c.category} ${c.amount}')
      .join(', ');

  /// The detailed figures, one section per kind (sections with nothing in
  /// them are left out).
  static void _details(StringBuffer b, AiSnapshotInput i) {
    if (i.incomeCategories.isNotEmpty) {
      b.writeln('Income by category this month: '
          '${_cats(i.incomeCategories)}.');
    }
    if (i.history.isNotEmpty) {
      b.writeln('Monthly history (oldest first; amounts in the base '
          'currency):');
      for (final AiMonthLine m in i.history) {
        b.write('- ${m.label}${m.current ? ' (in progress)' : ''}: income '
            '${m.income}, expenses ${m.expense}, net ${m.net}');
        if (m.categories.isNotEmpty) {
          b.write('; expenses by category: ${_cats(m.categories)}');
        }
        b.writeln('.');
      }
    }
    if (i.categoryBudgets.isNotEmpty) {
      b.writeln('Budget by category this month: ${i.categoryBudgets.map(
          (AiBudgetLine l) => '${l.category} planned ${l.planned}, spent '
              '${l.spent} (${_pct(l.used)})').join('; ')}.');
    }
    if (i.wallets.isNotEmpty) {
      b.writeln('Wallet balances (each in its own currency): ${i.wallets.map(
          (AiWalletLine w) => '${w.kind} ${w.balance}').join('; ')}.');
    }
    if (i.goals.isNotEmpty) {
      b.writeln('Goals: ${<String>[
        for (int n = 0; n < i.goals.length; n++)
          '#${n + 1} saved ${i.goals[n].saved} of ${i.goals[n].target} '
              '(${_pct(i.goals[n].progress)})'
              '${i.goals[n].deadline != null ? ', deadline ${i.goals[n].deadline}' : ''}',
      ].join('; ')}.');
    }
    if (i.recurring.isNotEmpty) {
      b.writeln('Recurring transactions: ${i.recurring.map(
          (AiRecurringLine r) => '${r.income ? 'income' : 'expense'} '
              '${r.category} ${r.amount} ${r.frequency}, next ${r.next}').join('; ')}.');
    }
    if (i.seasons.isNotEmpty) {
      b.writeln('Seasonal budgets: ${i.seasons.map((AiSeasonLine s) =>
          '${s.kind} ${s.start} to ${s.end} (${s.status}): budget ${s.budget}, '
          'set aside ${s.setAside}'
          '${s.spent != null ? ', spent ${s.spent}' : ''}').join('; ')}.');
    }
    if (i.darets.isNotEmpty) {
      b.writeln('Daret / savings circles: ${<String>[
        for (int n = 0; n < i.darets.length; n++)
          '#${n + 1} ${i.darets[n].contribution} ${i.darets[n].frequency}, '
              '${i.darets[n].paidRounds} of ${i.darets[n].rounds} rounds paid, '
              'my payout ${i.darets[n].myTurn} '
              '(${i.darets[n].payoutReceived ? 'received' : 'not received yet'})'
              '${i.darets[n].nextPayment != null ? ', next payment ${i.darets[n].nextPayment}' : ''}',
      ].join('; ')}.');
    }
  }
}
