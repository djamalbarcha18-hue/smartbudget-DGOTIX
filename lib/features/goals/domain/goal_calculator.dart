import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';

/// Goal status (V1 thresholds).
enum GoalStatus { completed, saving, notStarted }

/// Urgency tier for the smart recommendation (V1 horizons).
enum GoalUrgency { achieved, expired, relaxed, balanced, urgent }

/// Pure goal calculations — a faithful re-implementation of SmartBudget V1.
abstract final class GoalCalculator {
  /// progress = saved / target (0 when target is 0). Not clamped, so callers
  /// can show > 100% if over-saved; clamp for progress bars.
  static double progress(Goal g) {
    if (g.target.minorUnits == 0) return 0;
    return g.saved.minorUnits / g.target.minorUnits;
  }

  /// Whole months from today to the deadline (>= 0). Null when no deadline.
  static int? monthsRemaining(Goal g, {DateTime? now}) {
    final DateTime? dl = g.deadline;
    if (dl == null) return null;
    final DateTime t = now ?? DateTime.now();
    final int months = (dl.year - t.year) * 12 + (dl.month - t.month);
    return months < 0 ? 0 : months;
  }

  /// Required monthly contribution to reach the target by the deadline.
  /// V1: 0 when already reached; else (target - saved) / monthsRemaining,
  /// and the whole remaining amount when the horizon is 0/unknown.
  static Money monthlyInstallment(Goal g, {DateTime? now}) {
    final int remaining = g.target.minorUnits - g.saved.minorUnits;
    if (remaining <= 0) return Money.zero(g.target.currencyCode);
    final int? months = monthsRemaining(g, now: now);
    if (months == null || months == 0) {
      return Money(remaining, g.target.currencyCode);
    }
    return Money((remaining / months).round(), g.target.currencyCode);
  }

  static GoalStatus status(Goal g) {
    final double p = progress(g);
    if (p >= 1) return GoalStatus.completed;
    if (p >= 0.01) return GoalStatus.saving;
    return GoalStatus.notStarted;
  }

  /// Recommendation tier (text is localized in the UI). V1 horizons: > 24
  /// months relaxed, > 6 balanced, else urgent; expired when the deadline
  /// passed without completing.
  static GoalUrgency urgency(Goal g, {DateTime? now}) {
    if (progress(g) >= 1) return GoalUrgency.achieved;
    final int? months = monthsRemaining(g, now: now);
    if (months == 0) return GoalUrgency.expired;
    if (months == null) return GoalUrgency.balanced;
    if (months > 24) return GoalUrgency.relaxed;
    if (months > 6) return GoalUrgency.balanced;
    return GoalUrgency.urgent;
  }
}
