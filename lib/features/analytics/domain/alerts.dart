import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/domain/goal_calculator.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// How urgent an alert is (drives color + ordering).
enum AlertSeverity { high, medium, info, success }

/// The kind of alert — the UI turns this into localized title/description.
enum AlertKind {
  budgetOver,
  budgetNear,
  netNegative,
  savingsLow,
  goalOverdue,
  goalUrgent,

  /// A recurring transaction falls due within the next few days.
  recurringUpcoming,

  /// It's time to download a backup file.
  backupDue,
}

/// A derived, data-backed alert. Never fabricated: every instance comes from a
/// real threshold crossing computed by [AlertEngine].
class AppAlert {
  const AppAlert({
    required this.kind,
    required this.severity,
    required this.subject,
    required this.amount,
    required this.route,
    this.focusKey = '',
    this.date,
  });

  final AlertKind kind;
  final AlertSeverity severity;

  /// Category or goal name the alert is about ('' when not applicable).
  final String subject;

  /// Context amount (overspend, remaining, required monthly, …).
  final Money amount;

  /// Where the alert's action navigates.
  final String route;

  /// Stable key of the element to highlight on the destination page — the
  /// category for budget alerts, the goal id for goal alerts ('' otherwise).
  final String focusKey;

  /// The date the alert is about (e.g. a recurring item's due date).
  final DateTime? date;
}

/// Pure alert engine — turns real aggregates into alerts. No Flutter, no l10n,
/// fully unit-testable. Emits an alert ONLY when a real threshold is crossed.
abstract final class AlertEngine {
  static const double _savingsFloor = 0.10; // 10%
  static const double _budgetNearRatio = 0.9; // 90% of the planned amount

  static List<AppAlert> build({
    required Map<String, int> plannedByCategory, // minor units
    required Map<String, int> actualByCategory, // minor units
    required List<Goal> goals,
    required FinanceSummary yearSummary,
    required String currency,
    DateTime? now,
  }) {
    final List<AppAlert> out = <AppAlert>[];

    // --- Budget thresholds (selected month) ---
    plannedByCategory.forEach((String cat, int planned) {
      if (planned <= 0) return;
      final int actual = actualByCategory[cat] ?? 0;
      if (actual > planned) {
        out.add(AppAlert(
          kind: AlertKind.budgetOver,
          severity: AlertSeverity.high,
          subject: cat,
          amount: Money(actual - planned, currency),
          route: '/budget',
          focusKey: cat,
        ));
      } else if (actual >= planned * _budgetNearRatio) {
        out.add(AppAlert(
          kind: AlertKind.budgetNear,
          severity: AlertSeverity.medium,
          subject: cat,
          amount: Money(planned - actual, currency),
          route: '/budget',
          focusKey: cat,
        ));
      }
    });

    // --- Cash-flow / savings (only when there is data) ---
    if (yearSummary.count > 0 && yearSummary.income.minorUnits > 0) {
      if (yearSummary.net.minorUnits < 0) {
        out.add(AppAlert(
          kind: AlertKind.netNegative,
          severity: AlertSeverity.high,
          subject: '',
          amount: Money(-yearSummary.net.minorUnits, currency),
          route: '/reports',
        ));
      } else if (yearSummary.savingsRate < _savingsFloor) {
        out.add(AppAlert(
          kind: AlertKind.savingsLow,
          severity: AlertSeverity.medium,
          subject: '',
          amount: Money.zero(currency),
          route: '/health',
        ));
      }
    }

    // --- Goals behind schedule ---
    for (final Goal g in goals) {
      if (g.deadline == null || GoalCalculator.progress(g) >= 1) continue;
      final int? months = GoalCalculator.monthsRemaining(g, now: now);
      if (months == 0) {
        out.add(AppAlert(
          kind: AlertKind.goalOverdue,
          severity: AlertSeverity.high,
          subject: g.name,
          amount: GoalCalculator.monthlyInstallment(g, now: now),
          route: '/goals',
          focusKey: g.id,
        ));
      } else if (months != null && months <= 6) {
        out.add(AppAlert(
          kind: AlertKind.goalUrgent,
          severity: AlertSeverity.medium,
          subject: g.name,
          amount: GoalCalculator.monthlyInstallment(g, now: now),
          route: '/goals',
          focusKey: g.id,
        ));
      }
    }

    out.sort((AppAlert a, AppAlert b) =>
        a.severity.index.compareTo(b.severity.index));
    return out;
  }
}
