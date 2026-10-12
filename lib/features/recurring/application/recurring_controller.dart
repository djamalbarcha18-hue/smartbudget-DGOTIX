import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/recurring/data/fake_recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// The active rules store, scoped to the signed-in user.
final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final RecurringRepository repo = FakeRecurringRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Live list of the user's recurring rules (oldest first).
final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(recurringRepositoryProvider).watchAll();
});

/// Variable-amount occurrences waiting for the real amount (oldest first).
final pendingRecurringProvider = Provider<List<PendingOccurrence>>((ref) {
  final List<RecurringRule> rules =
      ref.watch(recurringRulesProvider).valueOrNull ?? const <RecurringRule>[];
  return RecurrenceEngine.awaitingAmount(rules, AppClock.now());
});

final recurringActionsProvider =
    Provider<RecurringActions>(RecurringActions.new);

/// Auto-post runs are serialized across the app: each run starts after the
/// previous one finished, so it always sees that run's result.
Future<void> _queue = Future<void>.value();

class RecurringActions {
  RecurringActions(this._ref);
  final Ref _ref;

  RecurringRepository get _rules => _ref.read(recurringRepositoryProvider);

  static String newId() =>
      'rule-${AppClock.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Saves [txn] as the first occurrence of a new rule repeating at
  /// [frequency], then posts anything already due (a start date in the past
  /// catches up to today). With [variableAmount], later occurrences wait for
  /// the user to confirm the real amount instead of being posted.
  Future<void> startFrom(
    Transaction txn,
    RecurrenceFrequency frequency, {
    bool variableAmount = false,
  }) async {
    final String ruleId = newId();
    final DateTime start = RecurrenceEngine.dateOnly(txn.date);
    final RecurringRule rule = RecurringRule(
      id: ruleId,
      type: txn.type,
      category: txn.category,
      amount: txn.amount,
      description: txn.description,
      paymentMethod: txn.paymentMethod,
      notes: txn.notes,
      walletId: txn.walletId,
      frequency: frequency,
      startDate: start,
      lastPosted: start,
      variableAmount: variableAmount,
      createdAt: AppClock.now(),
    );
    final Transaction first = Transaction(
      id: RecurrenceEngine.occurrenceId(ruleId, start),
      date: txn.date,
      type: txn.type,
      category: txn.category,
      amount: txn.amount,
      description: txn.description,
      paymentMethod: txn.paymentMethod,
      notes: txn.notes,
      walletId: txn.walletId,
      baseAmount: txn.baseAmount,
      createdAt: txn.createdAt,
    );
    await _ref.read(transactionActionsProvider).add(first);
    await _rules.add(rule);
    await postDue();
  }

  Future<void> pause(RecurringRule rule) =>
      _rules.update(rule.copyWith(active: false));

  /// Resumes without back-filling the occurrences missed while paused.
  Future<void> resume(RecurringRule rule) async {
    await _rules.update(RecurrenceEngine.resume(rule, AppClock.now()));
    await postDue();
  }

  /// Changes what FUTURE occurrences post; past transactions stay as they are.
  Future<void> editTemplate(
    RecurringRule rule, {
    required Money amount,
    required String description,
  }) =>
      _rules.update(rule.copyWith(amount: amount, description: description));

  /// Records the occurrence of a variable-amount [rule] on [date] with the
  /// [amount] actually received or paid; that amount becomes the estimate for
  /// the next one.
  Future<void> confirmAmount(
    RecurringRule rule,
    DateTime date,
    Money amount,
  ) async {
    final DateTime day = RecurrenceEngine.dateOnly(date);
    Transaction txn = RecurrenceEngine.materialize(
      rule.copyWith(amount: amount),
      day,
      createdAt: AppClock.now(),
    );
    final String base = _ref.read(baseCurrencyProvider);
    if (amount.currencyCode != base) {
      txn = txn.copyWith(
        baseAmount:
            WalletMath.baseValue(amount, base, _ref.read(ratesProvider)),
      );
    }
    await _ref.read(financeRepositoryProvider).importMany(<Transaction>[txn]);
    await _rules.update(_movedTo(rule, day).copyWith(amount: amount));
  }

  /// Marks the occurrence of [rule] on [date] as not received or not paid
  /// this time: nothing is recorded and the next one is awaited.
  Future<void> skipOccurrence(RecurringRule rule, DateTime date) =>
      _rules.update(_movedTo(rule, RecurrenceEngine.dateOnly(date)));

  /// [rule] with `lastPosted` moved forward to [day] (never backwards).
  RecurringRule _movedTo(RecurringRule rule, DateTime day) =>
      day.isAfter(rule.lastPosted) ? rule.copyWith(lastPosted: day) : rule;

  /// Stops the rule for good. Transactions already posted are kept.
  Future<void> stop(RecurringRule rule) => _rules.delete(rule.id);

  /// Posts every occurrence that is due and returns how many transactions were
  /// added. Safe to call repeatedly: occurrence ids are stable, so a repeated
  /// run never duplicates.
  Future<int> postDue({DateTime? now}) {
    final Future<int> run = _queue.then((_) => _post(now ?? AppClock.now()));
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<int> _post(DateTime now) async {
    final List<RecurringRule> rules =
        await _ref.read(recurringRulesProvider.future);
    final PostingPlan plan = RecurrenceEngine.plan(rules, now);
    if (plan.isEmpty) return 0;
    // Foreign-currency occurrences get their base value at today's rate.
    final String base = _ref.read(baseCurrencyProvider);
    final Map<String, double> rates = _ref.read(ratesProvider);
    final List<Transaction> txns = <Transaction>[
      for (final Transaction t in plan.transactions)
        t.amount.currencyCode == base
            ? t
            : t.copyWith(
                baseAmount: WalletMath.baseValue(t.amount, base, rates)),
    ];
    final int added =
        await _ref.read(financeRepositoryProvider).importMany(txns);
    await _rules.updateMany(plan.updatedRules);
    return added;
  }
}
