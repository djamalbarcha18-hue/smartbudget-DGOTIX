import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/data/fake_project_repository.dart';
import 'package:smartbudget/features/portfolio/domain/portfolio_planner.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/portfolio/domain/project_repository.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final String userId = ref.watch(authControllerProvider).user?.id ?? 'guest';
  final ProjectRepository repo = FakeProjectRepository(userId: userId);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Projects saved before the funding plan read Financial goals (kept for
/// backups and moved into goals by [legacyProjectsMoveProvider]).
final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAll();
});

/// Moves projects saved on their own into Financial goals, once each: the
/// funding plan and the goals are one list. Re-runs when a restored backup
/// brings old projects back.
final legacyProjectsMoveProvider = Provider<void>((ref) {
  final List<Project> old =
      ref.watch(projectsProvider).valueOrNull ?? const <Project>[];
  if (old.isEmpty) return;
  final ProjectRepository projects = ref.read(projectRepositoryProvider);
  final GoalActions goals = ref.read(goalActionsProvider);
  Future<void>(() async {
    final List<Goal> have = await ref.read(goalsProvider.future);
    for (final Project p in old) {
      if (!have.any((Goal g) => g.id == p.id)) await goals.add(p.toGoal());
      await projects.delete(p.id);
    }
  });
});

/// The funding plan's items: the Financial goals, each in its horizon.
final planProjectsProvider = Provider<List<Project>>((ref) {
  ref.watch(legacyProjectsMoveProvider);
  final DateTime now = AppClock.now();
  return <Project>[
    for (final Goal g in ref.watch(goalsProvider).valueOrNull ?? const <Goal>[])
      Project.fromGoal(g, now),
  ];
});

/// The user's monthly saving capacity (minor units), persisted per viewer.
/// Feeds the waterfall allocator. 0 means "not set yet".
final portfolioCapacityProvider =
    NotifierProvider<PortfolioCapacityController, int>(
        PortfolioCapacityController.new);

class PortfolioCapacityController extends Notifier<int> {
  static const String _base = 'sb_portfolio_capacity';
  String _key = '';

  @override
  int build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _key = AccountKeys.of(_base, account);
    _load(account);
    return 0;
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (await AccountKeys.open(p, _base, account) != _key) {
        return; // another account signed in meanwhile
      }
      final int? v = p.getInt(_key);
      if (v != null) state = v;
    } catch (_) {
      // Keep default.
    }
  }

  Future<void> set(int minorUnits) async {
    state = minorUnits < 0 ? 0 : minorUnits;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setInt(_key, state);
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// A suggested capacity derived from the user's data: average monthly net
/// (this year's net income ÷ 12), never negative. Just a hint.
final suggestedCapacityProvider = Provider<Money>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final FinanceSummary summary = ref.watch(financeSummaryProvider);
  final int perMonth = summary.net.minorUnits ~/ 12;
  return Money(perMonth < 0 ? 0 : perMonth, currency);
});

/// The full portfolio plan (waterfall funding) for the current projects,
/// capacity and base currency.
final portfolioPlanProvider = Provider<PortfolioPlan>((ref) {
  final List<Project> projects = ref.watch(planProjectsProvider);
  final int capacity = ref.watch(portfolioCapacityProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return PortfolioPlanner.build(
    projects: projects,
    capacityMinor: capacity,
    currency: currency,
  );
});

final projectActionsProvider = Provider<ProjectActions>((ref) {
  return ProjectActions(ref.watch(goalActionsProvider),
      () => ref.read(goalsProvider).valueOrNull ?? const <Goal>[]);
});

/// The funding plan's actions, on the Financial goals behind it.
class ProjectActions {
  ProjectActions(this._goals, this._current);
  final GoalActions _goals;
  final List<Goal> Function() _current;

  Future<void> add(Project p) => _goals.add(p.toGoal());
  Future<void> update(Project p) => _goals.update(p.toGoal());
  Future<void> delete(String id) => _goals.delete(id);

  /// Adds to the goal's saved amount (never negative); the rest of the goal,
  /// its horizon included, stays as it is.
  Future<void> contribute(Project p, Money amount) async {
    final Goal? g =
        _current().where((Goal g) => g.id == p.id).firstOrNull;
    if (g != null) await _goals.contribute(g, amount);
  }

  static String newId() => GoalActions.newId();
}
