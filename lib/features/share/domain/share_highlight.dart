/// The "My progress" share card: picks the user's proudest highlight to show.
///
/// Privacy first: only a score, a percentage or a count ever leaves the app —
/// never an amount, a category or a goal name. And only good news is put
/// forward: a weak score is never pushed onto a public card; the user still
/// gets a positive "I started" card instead.
library;

import 'package:smartbudget/features/financial_health/domain/health_engine.dart';

enum HighlightKind { goals, health, savings, journey }

class ShareHighlight {
  const ShareHighlight({
    required this.kind,
    this.healthScore,
    this.healthStatus,
    this.savingsPct,
    this.goalsCompleted = 0,
  });

  final HighlightKind kind;

  /// Set only when the score is worth sharing (Good or better).
  final int? healthScore;
  final HealthStatus? healthStatus;

  /// Set only when the savings rate is worth sharing.
  final int? savingsPct;

  final int goalsCompleted;

  static const int minHealthScore = 55;
  static const int minSavingsPct = 10;

  static ShareHighlight pick({
    required bool hasData,
    required double healthScore,
    required double savingsRate,
    required int goalsCompleted,
  }) {
    final int score = healthScore.round().clamp(0, 100);
    final int pct = (savingsRate * 100).round().clamp(0, 100);
    final bool showHealth = hasData && score >= minHealthScore;
    final bool showSavings = hasData && pct >= minSavingsPct;
    final HighlightKind kind = goalsCompleted > 0
        ? HighlightKind.goals
        : showHealth
            ? HighlightKind.health
            : showSavings
                ? HighlightKind.savings
                : HighlightKind.journey;
    return ShareHighlight(
      kind: kind,
      healthScore: showHealth ? score : null,
      healthStatus: showHealth ? statusOf(score.toDouble()) : null,
      savingsPct: showSavings ? pct : null,
      goalsCompleted: goalsCompleted < 0 ? 0 : goalsCompleted,
    );
  }

  /// Secondary facts shown as chips under the headline (never the headline
  /// itself again).
  List<HighlightKind> get extras => <HighlightKind>[
        if (kind != HighlightKind.health && healthScore != null)
          HighlightKind.health,
        if (kind != HighlightKind.savings && savingsPct != null)
          HighlightKind.savings,
        if (kind != HighlightKind.goals && goalsCompleted > 0)
          HighlightKind.goals,
      ];
}
