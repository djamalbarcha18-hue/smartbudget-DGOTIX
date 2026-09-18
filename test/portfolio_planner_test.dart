import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/portfolio/domain/portfolio_planner.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';

const String usd = 'USD';
final DateTime now = DateTime(2026, 1, 1);

Project _p({
  required String id,
  required double target,
  double saved = 0,
  ProjectHorizon horizon = ProjectHorizon.mid,
  DateTime? date,
}) =>
    Project(
      id: id,
      name: id,
      target: Money.fromDouble(target, usd),
      saved: Money.fromDouble(saved, usd),
      horizon: horizon,
      targetDate: date,
      createdAt: now,
    );

ProjectPlan _byId(PortfolioPlan plan, String id) =>
    plan.plans.firstWhere((ProjectPlan p) => p.project.id == id);

void main() {
  group('PortfolioPlanner required monthly', () {
    test('required = ceil(remaining / months) with an explicit date', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: <Project>[
          _p(id: 'a', target: 3000, date: DateTime(2026, 4, 1)), // 3 months
        ],
        capacityMinor: 0,
        currency: usd,
        now: now,
      );
      expect(_byId(plan, 'a').monthsRemaining, 3);
      expect(_byId(plan, 'a').requiredMonthly.asDouble, 1000);
    });

    test('no date falls back to the horizon default window', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: <Project>[_p(id: 'a', target: 4800, horizon: ProjectHorizon.long)],
        capacityMinor: 0,
        currency: usd,
        now: now,
      );
      // long default = 48 months → 4800/48 = 100.
      expect(_byId(plan, 'a').requiredMonthly.asDouble, 100);
    });
  });

  group('Waterfall allocation (nearest deadline first)', () {
    final List<Project> projects = <Project>[
      _p(id: 'mid', target: 2400, date: DateTime(2027, 1, 1)), // 12mo → 200/mo
      _p(id: 'near', target: 3000, date: DateTime(2026, 4, 1)), // 3mo → 1000/mo
    ];

    test('funds the nearest deadline first when capacity is tight', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: projects,
        capacityMinor: Money.fromDouble(1000, usd).minorUnits,
        currency: usd,
        now: now,
      );
      expect(_byId(plan, 'near').allocatedMonthly.asDouble, 1000);
      expect(_byId(plan, 'near').status, ProjectFundStatus.funded);
      expect(_byId(plan, 'mid').allocatedMonthly.asDouble, 0);
      expect(_byId(plan, 'mid').status, ProjectFundStatus.unfunded);
      expect(plan.totalRequiredMonthly.asDouble, 1200);
      expect(plan.feasible, isFalse);
      expect(plan.shortfall.asDouble, 200);
    });

    test('full capacity funds everything, feasible with no shortfall', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: projects,
        capacityMinor: Money.fromDouble(1200, usd).minorUnits,
        currency: usd,
        now: now,
      );
      expect(plan.feasible, isTrue);
      expect(plan.shortfall.asDouble, 0);
      expect(_byId(plan, 'near').status, ProjectFundStatus.funded);
      expect(_byId(plan, 'mid').status, ProjectFundStatus.funded);
    });
  });

  group('Statuses', () {
    test('a reached target is completed and excluded from required', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: <Project>[_p(id: 'done', target: 500, saved: 500)],
        capacityMinor: Money.fromDouble(100, usd).minorUnits,
        currency: usd,
        now: now,
      );
      expect(_byId(plan, 'done').status, ProjectFundStatus.completed);
      expect(plan.totalRequiredMonthly.asDouble, 0);
      expect(plan.feasible, isTrue);
    });

    test('a passed date on an unfinished project is overdue', () {
      final PortfolioPlan plan = PortfolioPlanner.build(
        projects: <Project>[
          _p(id: 'late', target: 1000, date: DateTime(2025, 6, 1)),
        ],
        capacityMinor: 0,
        currency: usd,
        now: now,
      );
      expect(_byId(plan, 'late').monthsRemaining, 0);
      expect(_byId(plan, 'late').status, ProjectFundStatus.overdue);
    });
  });
}
