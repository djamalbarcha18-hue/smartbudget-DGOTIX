import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';

/// Per-project funding status after the waterfall allocation.
enum ProjectFundStatus { completed, funded, partial, unfunded, overdue }

/// A single project's computed plan.
class ProjectPlan {
  const ProjectPlan({
    required this.project,
    required this.monthsRemaining,
    required this.requiredMonthly,
    required this.allocatedMonthly,
    required this.progress,
    required this.status,
    required this.monthsToCompleteAtPace,
  });

  final Project project;

  /// Effective months to the deadline (explicit target date, else the
  /// horizon's default planning window). 0 means "due now / overdue".
  final int monthsRemaining;

  /// Contribution needed each month to hit the target on time.
  final Money requiredMonthly;

  /// Contribution this project receives this month from the waterfall.
  final Money allocatedMonthly;

  /// saved / target (not clamped; clamp in the UI).
  final double progress;

  final ProjectFundStatus status;

  /// Months to finish at the current allocated pace (null if nothing is
  /// allocated, or already complete).
  final int? monthsToCompleteAtPace;

  bool get isActive =>
      status != ProjectFundStatus.completed && project.remainingMinor > 0;
}

/// Portfolio-wide roll-up.
class PortfolioPlan {
  const PortfolioPlan({
    required this.plans,
    required this.totalTarget,
    required this.totalSaved,
    required this.totalRequiredMonthly,
    required this.capacity,
    required this.allocatedTotal,
    required this.surplus,
    required this.shortfall,
    required this.feasible,
  });

  final List<ProjectPlan> plans;
  final Money totalTarget;
  final Money totalSaved;

  /// Sum of every active project's required monthly contribution.
  final Money totalRequiredMonthly;

  /// The user's monthly saving capacity fed into the waterfall.
  final Money capacity;

  /// Total allocated across projects this month (≤ capacity).
  final Money allocatedTotal;

  /// Capacity left after funding (capacity − allocatedTotal, ≥ 0).
  final Money surplus;

  /// Extra monthly money needed to fully fund everything on time (≥ 0).
  final Money shortfall;

  /// True when capacity covers every active project's required monthly.
  final bool feasible;

  List<ProjectPlan> forHorizon(ProjectHorizon h) =>
      plans.where((ProjectPlan p) => p.project.horizon == h).toList();
}

extension _ProjectMath on Project {
  int get remainingMinor {
    final int r = target.minorUnits - saved.minorUnits;
    return r < 0 ? 0 : r;
  }
}

/// Pure funding engine: computes each project's required monthly contribution
/// and allocates the user's monthly capacity across projects by a **waterfall**
/// — nearest deadline first — so the most time-critical projects are funded
/// before the rest. No riba/return promises: this plans disciplined saving,
/// not investment yield.
abstract final class PortfolioPlanner {
  static int effectiveMonths(Project p, DateTime now) {
    final DateTime? d = p.targetDate;
    if (d == null) return p.horizon.defaultMonths;
    final int months = (d.year - now.year) * 12 + (d.month - now.month);
    return months < 0 ? 0 : months;
  }

  static Money _requiredMonthly(Project p, int months, String currency) {
    final int remaining = p.remainingMinor;
    if (remaining <= 0) return Money.zero(currency);
    if (months <= 0) return Money(remaining, currency); // due now → all of it
    // Integer ceiling so contributions actually reach the target.
    return Money((remaining + months - 1) ~/ months, currency);
  }

  static PortfolioPlan build({
    required List<Project> projects,
    required int capacityMinor,
    required String currency,
    DateTime? now,
  }) {
    final DateTime t = now ?? DateTime.now();

    // Pre-compute per-project figures.
    final List<_Row> rows = projects.map((Project p) {
      final int months = effectiveMonths(p, t);
      final Money required = _requiredMonthly(p, months, currency);
      final double progress = p.target.minorUnits == 0
          ? 0
          : p.saved.minorUnits / p.target.minorUnits;
      return _Row(
        project: p,
        months: months,
        requiredMinor: required.minorUnits,
        progress: progress,
      );
    }).toList();

    // Waterfall: active projects, nearest deadline first, then smallest gap.
    final List<_Row> active = rows
        .where((_Row r) => r.project.remainingMinor > 0 && r.progress < 1)
        .toList()
      ..sort((_Row a, _Row b) {
        final int byMonths = a.months.compareTo(b.months);
        if (byMonths != 0) return byMonths;
        return a.project.remainingMinor.compareTo(b.project.remainingMinor);
      });

    int remainingCapacity = capacityMinor < 0 ? 0 : capacityMinor;
    final Map<String, int> allocated = <String, int>{};
    for (final _Row r in active) {
      final int give =
          r.requiredMinor <= remainingCapacity ? r.requiredMinor : remainingCapacity;
      allocated[r.project.id] = give;
      remainingCapacity -= give;
    }

    int totalTarget = 0;
    int totalSaved = 0;
    int totalRequired = 0;
    int allocatedTotal = 0;

    final List<ProjectPlan> plans = rows.map((_Row r) {
      totalTarget += r.project.target.minorUnits;
      totalSaved += r.project.saved.minorUnits;
      final int alloc = allocated[r.project.id] ?? 0;
      allocatedTotal += alloc;

      final ProjectFundStatus status;
      if (r.progress >= 1 || r.project.remainingMinor <= 0) {
        status = ProjectFundStatus.completed;
      } else {
        totalRequired += r.requiredMinor;
        if (r.months <= 0) {
          status = ProjectFundStatus.overdue;
        } else if (alloc >= r.requiredMinor && r.requiredMinor > 0) {
          status = ProjectFundStatus.funded;
        } else if (alloc > 0) {
          status = ProjectFundStatus.partial;
        } else {
          status = ProjectFundStatus.unfunded;
        }
      }

      final int? monthsToComplete = alloc > 0 && r.project.remainingMinor > 0
          ? (r.project.remainingMinor + alloc - 1) ~/ alloc
          : null;

      return ProjectPlan(
        project: r.project,
        monthsRemaining: r.months,
        requiredMonthly: Money(r.requiredMinor, currency),
        allocatedMonthly: Money(alloc, currency),
        progress: r.progress,
        status: status,
        monthsToCompleteAtPace: monthsToComplete,
      );
    }).toList();

    final int capacity = capacityMinor < 0 ? 0 : capacityMinor;
    final int shortfall =
        totalRequired > capacity ? totalRequired - capacity : 0;

    return PortfolioPlan(
      plans: plans,
      totalTarget: Money(totalTarget, currency),
      totalSaved: Money(totalSaved, currency),
      totalRequiredMonthly: Money(totalRequired, currency),
      capacity: Money(capacity, currency),
      allocatedTotal: Money(allocatedTotal, currency),
      surplus: Money(capacity - allocatedTotal, currency),
      shortfall: Money(shortfall, currency),
      feasible: shortfall == 0,
    );
  }
}

class _Row {
  _Row({
    required this.project,
    required this.months,
    required this.requiredMinor,
    required this.progress,
  });
  final Project project;
  final int months;
  final int requiredMinor;
  final double progress;
}
