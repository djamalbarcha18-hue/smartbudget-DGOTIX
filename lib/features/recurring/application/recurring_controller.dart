import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/recurring/data/fake_recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_repository.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

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
      'rule-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Saves [txn] as the first occurrence of a new rule repeating at
  /// [frequency], then posts anything already due (a start date in the past
  /// catches up to today).
  Future<void> startFrom(Transaction txn, RecurrenceFrequency frequency) async {
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
      frequency: frequency,
      startDate: start,
      lastPosted: start,
      createdAt: DateTime.now(),
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
    await _rules.update(RecurrenceEngine.resume(rule, DateTime.now()));
    await postDue();
  }

  /// Changes what FUTURE occurrences post; past transactions stay as they are.
  Future<void> editTemplate(
    RecurringRule rule, {
    required Money amount,
    required String description,
  }) =>
      _rules.update(rule.copyWith(amount: amount, description: description));

  /// Stops the rule for good. Transactions already posted are kept.
  Future<void> stop(RecurringRule rule) => _rules.delete(rule.id);

  /// Posts every occurrence that is due and returns how many transactions were
  /// added. Safe to call repeatedly: occurrence ids are stable, so a repeated
  /// run never duplicates.
  Future<int> postDue({DateTime? now}) {
    final Future<int> run =
        _queue.then((_) => _post(now ?? DateTime.now()));
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<int> _post(DateTime now) async {
    final List<RecurringRule> rules =
        await _ref.read(recurringRulesProvider.future);
    final PostingPlan plan = RecurrenceEngine.plan(rules, now);
    if (plan.isEmpty) return 0;
    final int added = await _ref
        .read(financeRepositoryProvider)
        .importMany(plan.transactions);
    await _rules.updateMany(plan.updatedRules);
    return added;
  }
}
