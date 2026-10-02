import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/assistant/domain/ai_conversation.dart';
import 'package:smartbudget/features/assistant/domain/ai_snapshot.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/seasons/application/seasons_controller.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

export 'package:smartbudget/features/assistant/domain/ai_conversation.dart'
    show ChatMessage;

/// A REAL-DATA snapshot of the user's finances, handed to the model as context
/// so answers are personal and specific (see [AiSnapshot]): the month, 12
/// months of history by category, budgets, wallets, goals, recurring
/// transactions, seasons and daret. Only figures the app already computed —
/// never guessed — and no descriptions, notes or names.
final aiContextProvider = Provider<String>((ref) {
  final DateTime now = AppClock.now();
  final String currency = ref.watch(baseCurrencyProvider);
  final List<Transaction> all =
      ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
  String m(Money v) => MoneyFormatter.format(v).replaceAll('\u200E', '');
  String two(int v) => v.toString().padLeft(2, '0');
  String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
  final String todayLabel = ymd(now);

  if (all.isEmpty) {
    return AiSnapshot.build(AiSnapshotInput(
        currency: currency, today: todayLabel, hasData: false));
  }

  final List<Transaction> monthTx =
      FinanceCalculator.forMonth(all, now.year, now.month);
  final FinanceSummary month = FinanceCalculator.summarize(monthTx, currency);
  final DateTime pm = DateTime(now.year, now.month - 1, 1);
  final FinanceSummary prev = FinanceCalculator.summarize(
      FinanceCalculator.forMonth(all, pm.year, pm.month), currency);
  final FinanceSummary year = FinanceCalculator.summarize(
      FinanceCalculator.forYear(all, now.year), currency);
  final List<CategoryTotal> cats = FinanceCalculator.categoryTotals(
      monthTx, TransactionType.expense, currency);
  final int monthSpend = month.expense.minorUnits;

  // Budget planned for this calendar month (base currency), in total and
  // per category.
  int planned = 0;
  final Map<String, int> spentByCat = <String, int>{
    for (final CategoryTotal c in cats) c.category: c.amount.minorUnits,
  };
  final List<AiBudgetLine> categoryBudgets = <AiBudgetLine>[];
  for (final BudgetTarget t
      in ref.watch(budgetsProvider).valueOrNull ?? const <BudgetTarget>[]) {
    if (t.year == now.year &&
        t.month == now.month &&
        t.planned.currencyCode == currency) {
      planned += t.planned.minorUnits;
      final int spent = spentByCat[t.category] ?? 0;
      categoryBudgets.add(AiBudgetLine(
          t.category,
          m(t.planned),
          m(Money(spent, currency)),
          t.planned.minorUnits > 0 ? spent / t.planned.minorUnits : 0));
    }
  }

  // The last 12 months, oldest first, this month last.
  final List<AiMonthLine> history = <AiMonthLine>[];
  for (int back = 11; back >= 0; back--) {
    final DateTime d = DateTime(now.year, now.month - back, 1);
    final List<Transaction> tx = FinanceCalculator.forMonth(all, d.year, d.month);
    final FinanceSummary sum = FinanceCalculator.summarize(tx, currency);
    if (sum.count == 0) continue;
    history.add(AiMonthLine(
      label: '${d.year}-${two(d.month)}',
      income: m(sum.income),
      expense: m(sum.expense),
      net: m(sum.net),
      current: back == 0,
      categories: <AiCategoryLine>[
        for (final CategoryTotal c in FinanceCalculator.categoryTotals(
            tx, TransactionType.expense, currency))
          AiCategoryLine(c.category, m(c.amount),
              sum.expense.minorUnits > 0
                  ? c.amount.minorUnits / sum.expense.minorUnits
                  : 0),
      ],
    ));
  }

  // Goals (base currency).
  int saved = 0;
  int target = 0;
  int goalCount = 0;
  final List<AiGoalLine> goals = <AiGoalLine>[];
  for (final Goal g in ref.watch(goalsProvider).valueOrNull ?? const <Goal>[]) {
    goals.add(AiGoalLine(
      saved: m(g.saved),
      target: m(g.target),
      progress: g.target.minorUnits > 0
          ? g.saved.minorUnits / g.target.minorUnits
          : 0,
      deadline: g.deadline != null ? ymd(g.deadline!) : null,
    ));
    if (g.target.currencyCode != currency) continue;
    goalCount++;
    saved += g.saved.minorUnits;
    target += g.target.minorUnits;
  }

  // Recurring items due in the next 7 days.
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime limit = DateTime(now.year, now.month, now.day + 7);
  int dueCount = 0;
  int dueTotal = 0;
  final List<AiRecurringLine> recurring = <AiRecurringLine>[];
  for (final RecurringRule r in ref.watch(recurringRulesProvider).valueOrNull ??
      const <RecurringRule>[]) {
    if (!r.active) continue;
    final DateTime next = RecurrenceEngine.nextOccurrence(r);
    recurring.add(AiRecurringLine(
      income: r.type == TransactionType.income,
      category: r.category,
      amount: m(r.amount),
      frequency: r.frequency.name,
      next: ymd(next),
    ));
    if (next.isBefore(today) || next.isAfter(limit)) continue;
    dueCount++;
    if (r.type == TransactionType.expense &&
        r.amount.currencyCode == currency) {
      dueTotal += r.amount.minorUnits;
    }
  }

  // Wallets: only once the user added one of their own (otherwise
  // "General" just repeats the overall balance). Named by kind, never by the
  // user's label.
  final List<AiWalletLine> wallets = <AiWalletLine>[];
  if (ref.watch(hasWalletsProvider)) {
    final Map<String, int> balances = ref.watch(walletBalancesProvider);
    final List<Wallet> ws = ref.watch(walletsProvider);
    for (int n = 0; n < ws.length; n++) {
      final Wallet w = ws[n];
      wallets.add(AiWalletLine(
        w.isGeneral ? 'general' : '${w.type.name} #${n + 1}',
        m(Money(balances[w.id] ?? 0, w.currency)),
      ));
    }
  }

  // Seasonal budgets that ended less than a year ago or are still to come.
  final List<AiSeasonLine> seasons = <AiSeasonLine>[
    for (final SeasonPlan p in ref.watch(seasonPlansProvider).valueOrNull ??
        const <SeasonPlan>[])
      if (p.end.isAfter(DateTime(now.year - 1, now.month, now.day)))
        AiSeasonLine(
          kind: p.kind.name,
          start: ymd(p.start),
          end: ymd(p.end),
          status: SeasonMath.status(p, now).name,
          budget: m(p.budget),
          setAside: m(p.saved),
          spent: SeasonMath.status(p, now) == SeasonStatus.upcoming
              ? null
              : m(SeasonMath.spent(p, all, currency)),
        ),
  ];

  final List<AiDaretLine> darets = <AiDaretLine>[
    for (final Daret d
        in ref.watch(daretsProvider).valueOrNull ?? const <Daret>[])
      // Skip groups that are over and settled.
      if (!DaretMath.finished(d, now) || !d.payoutReceived)
        AiDaretLine(
          contribution: m(d.contribution),
          frequency: d.frequency.name,
          rounds: d.rounds,
          paidRounds: d.paidRounds.where((int r) => r < d.rounds).length,
          myTurn: ymd(DaretMath.myTurn(d)),
          payoutReceived: d.payoutReceived,
          nextPayment: DaretMath.nextUnpaid(d) != null
              ? ymd(DaretMath.roundDate(d, DaretMath.nextUnpaid(d)!))
              : null,
        ),
  ];

  final DebtSummary debts = ref.watch(debtSummaryProvider);
  final ZakatResult zakat = ref.watch(zakatResultProvider);
  final HealthReport health = ref.watch(healthReportProvider);

  return AiSnapshot.build(AiSnapshotInput(
    currency: currency,
    today: todayLabel,
    hasData: true,
    monthLabel: '${now.year}-${two(now.month)}',
    monthIncome: m(month.income),
    monthExpense: m(month.expense),
    monthNet: m(month.net),
    prevMonthIncome: prev.count > 0 ? m(prev.income) : null,
    prevMonthExpense: prev.count > 0 ? m(prev.expense) : null,
    yearIncome: m(year.income),
    yearExpense: m(year.expense),
    yearNet: m(year.net),
    yearSavingsRate: year.income.minorUnits > 0 ? year.savingsRate : null,
    topCategories: <AiCategoryLine>[
      for (final CategoryTotal c in cats.take(5))
        AiCategoryLine(c.category, m(c.amount),
            monthSpend > 0 ? c.amount.minorUnits / monthSpend : 0),
    ],
    budgetPlanned: planned > 0 ? m(Money(planned, currency)) : null,
    budgetSpent: planned > 0 ? m(month.expense) : null,
    budgetUsed: planned > 0 ? monthSpend / planned : null,
    goalsCount: goalCount,
    goalsSaved: goalCount > 0 ? m(Money(saved, currency)) : null,
    goalsTarget: goalCount > 0 ? m(Money(target, currency)) : null,
    goalsProgress: target > 0 ? saved / target : null,
    owedToMe: debts.owedToMe.isZero ? null : m(debts.owedToMe),
    owedByMe: debts.owedByMe.isZero ? null : m(debts.owedByMe),
    recurringDueCount: dueCount,
    recurringDueTotal: m(Money(dueTotal, currency)),
    zakatDue: zakat.obligatory ? m(zakat.due) : null,
    healthScore: health.hasData ? health.score.round() : null,
    healthStatus: health.hasData ? health.status.name : null,
    healthConfidence: health.hasData ? health.confidence.round() : null,
    incomeCategories: <AiCategoryLine>[
      for (final CategoryTotal c in FinanceCalculator.categoryTotals(
          monthTx, TransactionType.income, currency))
        AiCategoryLine(c.category, m(c.amount),
            month.income.minorUnits > 0
                ? c.amount.minorUnits / month.income.minorUnits
                : 0),
    ],
    history: history,
    categoryBudgets: categoryBudgets,
    wallets: wallets,
    goals: goals,
    recurring: recurring,
    seasons: seasons,
    darets: darets,
  ));
});

/// The saved conversation, persisted on-device so it survives reloads. Capped to
/// the most recent [_maxStored] turns to stay small.
final chatMessagesProvider =
    NotifierProvider<ChatMessagesController, List<ChatMessage>>(
        ChatMessagesController.new);

class ChatMessagesController extends Notifier<List<ChatMessage>> {
  static const String _key = 'sb_ai_chat';
  static const int _maxStored = 40;

  @override
  List<ChatMessage> build() {
    _load();
    return const <ChatMessage>[];
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((dynamic e) =>
              ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      // Keep empty on any corruption.
    }
  }

  void add(ChatMessage m) {
    final List<ChatMessage> next = <ChatMessage>[...state, m];
    state = next.length > _maxStored
        ? next.sublist(next.length - _maxStored)
        : next;
    _persist();
  }

  void clear() {
    state = const <ChatMessage>[];
    _persist();
  }

  /// Drops one message (a reported answer is hidden this way).
  void remove(ChatMessage m) {
    state = <ChatMessage>[
      for (final ChatMessage x in state)
        if (!identical(x, m)) x,
    ];
    _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (state.isEmpty) {
        await p.remove(_key);
      } else {
        await p.setString(
            _key,
            jsonEncode(state
                .map((ChatMessage m) => m.toJson())
                .toList(growable: false)));
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}
