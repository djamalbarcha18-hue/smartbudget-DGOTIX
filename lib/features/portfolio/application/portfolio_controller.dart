import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
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

final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAll();
});

/// The user's monthly saving capacity (minor units), persisted per viewer.
/// Feeds the waterfall allocator. 0 means "not set yet".
final portfolioCapacityProvider =
    NotifierProvider<PortfolioCapacityController, int>(
        PortfolioCapacityController.new);

class PortfolioCapacityController extends Notifier<int> {
  static const String _key = 'sb_portfolio_capacity';

  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
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
  final List<Project> projects =
      ref.watch(projectsProvider).valueOrNull ?? const <Project>[];
  final int capacity = ref.watch(portfolioCapacityProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  return PortfolioPlanner.build(
    projects: projects,
    capacityMinor: capacity,
    currency: currency,
  );
});

final projectActionsProvider = Provider<ProjectActions>((ref) {
  return ProjectActions(ref.watch(projectRepositoryProvider));
});

class ProjectActions {
  ProjectActions(this._repo);
  final ProjectRepository _repo;

  Future<void> add(Project p) => _repo.add(p);
  Future<void> update(Project p) => _repo.update(p);
  Future<void> delete(String id) => _repo.delete(id);

  /// Adds a contribution to the project's derived saved amount (never negative).
  Future<void> contribute(Project p, Money amount) {
    final int next = p.saved.minorUnits + amount.minorUnits;
    return _repo.update(
      p.copyWith(saved: Money(next < 0 ? 0 : next, p.target.currencyCode)),
    );
  }

  static String newId() =>
      'proj-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
