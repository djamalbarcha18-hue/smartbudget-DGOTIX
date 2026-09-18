/// Pure period-over-period KPI math. No Flutter, no formatting — just the
/// numbers and their meaning, so it is fully unit-testable and reused by every
/// KPI on the dashboard (single source of calculation).

/// Raw direction of a change (before any semantic interpretation).
enum KpiDirection { up, down, flat }

/// How a change should be read for THIS metric. Income up is good; expenses up
/// is bad — the meaning is per-KPI, never assumed from the arrow alone.
enum KpiSentiment { good, bad, neutral }

/// The computed change of a KPI between two equivalent periods.
class KpiChange {
  const KpiChange({
    required this.absolute,
    required this.percentage,
    required this.direction,
    required this.comparable,
  });

  /// current − previous (minor units, or whatever integer unit is passed).
  final int absolute;

  /// Signed fraction (0.125 == +12.5%). Null when no valid comparison exists.
  final double? percentage;

  final KpiDirection direction;

  /// False when there is no meaningful baseline (no previous data, or a zero
  /// previous value) — the UI must then show "no comparison", never 0% or an
  /// invented number.
  final bool comparable;

  /// Compares [current] with [previous]. [hasPrevious] is false when the prior
  /// period has no data at all.
  factory KpiChange.of({
    required int current,
    required int previous,
    required bool hasPrevious,
  }) {
    final int abs = current - previous;
    final KpiDirection dir = abs > 0
        ? KpiDirection.up
        : (abs < 0 ? KpiDirection.down : KpiDirection.flat);
    if (!hasPrevious || previous == 0) {
      return KpiChange(
          absolute: abs, percentage: null, direction: dir, comparable: false);
    }
    return KpiChange(
      absolute: abs,
      percentage: abs / previous.abs(),
      direction: dir,
      comparable: true,
    );
  }

  /// Semantic reading given the KPI's positive direction.
  KpiSentiment sentiment({required bool positiveWhenUp}) {
    switch (direction) {
      case KpiDirection.flat:
        return KpiSentiment.neutral;
      case KpiDirection.up:
        return positiveWhenUp ? KpiSentiment.good : KpiSentiment.bad;
      case KpiDirection.down:
        return positiveWhenUp ? KpiSentiment.bad : KpiSentiment.good;
    }
  }
}
