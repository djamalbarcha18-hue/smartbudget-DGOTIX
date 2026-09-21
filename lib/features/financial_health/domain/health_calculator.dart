// Backward-compatibility surface for the financial-health feature.
//
// The scoring logic now lives in the central [HealthEngine] (health_engine.dart)
// which produces a rich [HealthReport]. This file keeps the small, stable types
// that other features already depend on ([HealthStatus] and a slim
// [HealthResult] with score + status), so the dashboard hero card and the AI
// assistant keep working unchanged.
export 'package:smartbudget/features/financial_health/domain/health_engine.dart'
    show HealthStatus;

import 'package:smartbudget/features/financial_health/domain/health_engine.dart';

/// A compact view of the health outcome (score + status band) for consumers
/// that only need the headline number, not the full report.
class HealthResult {
  const HealthResult({required this.score, required this.status});
  final double score;
  final HealthStatus status;

  factory HealthResult.fromReport(HealthReport r) =>
      HealthResult(score: r.score, status: r.status);
}
