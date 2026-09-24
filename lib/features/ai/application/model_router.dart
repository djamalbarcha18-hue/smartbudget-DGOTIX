import 'package:smartbudget/features/ai/application/ai_config.dart';
import 'package:smartbudget/features/ai/domain/ai_registry.dart';

/// Chooses which models to try for a task, from capabilities + kill switches +
/// priority + cost — never by hardcoded name. Returns an ordered list: the
/// primary first, then fallbacks. The caller stops after
/// `1 + config.maxFallbackAttempts`.
abstract final class ModelRouter {
  /// Capabilities a task strictly requires. A model missing any is rejected
  /// (e.g. Receipt Scan needs image + structured output).
  static Set<AiCapability> requirementsFor(AiTaskType task) => switch (task) {
        AiTaskType.receiptScan ||
        AiTaskType.receiptRetry =>
          const <AiCapability>{
            AiCapability.image,
            AiCapability.structuredOutput,
          },
        AiTaskType.chat ||
        AiTaskType.analysis ||
        AiTaskType.financialInsight ||
        AiTaskType.report =>
          const <AiCapability>{AiCapability.text},
      };

  /// Whether cheap-first ordering is allowed. Correctness-critical tasks
  /// (receipts, financial data) prefer capable models over the cheapest.
  static bool _costSensitive(AiTaskType task) => switch (task) {
        AiTaskType.chat || AiTaskType.analysis => true,
        AiTaskType.financialInsight ||
        AiTaskType.report ||
        AiTaskType.receiptScan ||
        AiTaskType.receiptRetry =>
          false,
      };

  /// Ordered candidate models for [task] across ALL enabled providers.
  /// [preferred] (e.g. the user's connected provider) is tried first.
  static List<AiModel> candidatesFor(
    AiTaskType task,
    AiConfig config, {
    AiProviderId? preferred,
  }) {
    final Set<AiCapability> need = requirementsFor(task);
    final List<AiModel> pool = <AiModel>[
      for (final AiModel m in ModelRegistry.all)
        if (m.isActive &&
            config.isProviderEnabled(m.provider) &&
            config.isModelEnabled(m.id) &&
            need.every(m.supports))
          m,
    ];

    final bool cheap = _costSensitive(task);
    pool.sort((AiModel a, AiModel b) {
      // Preferred provider first.
      final int pa = a.provider == preferred ? 0 : 1;
      final int pb = b.provider == preferred ? 0 : 1;
      if (pa != pb) return pa - pb;
      // Then task-appropriate ordering.
      if (cheap) {
        final double ca = a.inputPer1M + a.outputPer1M;
        final double cb = b.inputPer1M + b.outputPer1M;
        if (ca != cb) return ca.compareTo(cb);
      }
      return a.priority.compareTo(b.priority);
    });
    return pool;
  }

  /// Candidate MODELS within a single provider (one key, so failover stays
  /// inside that provider). Ordered primary → fallbacks, with an
  /// optional preferred model id pinned first when it is still usable.
  static List<AiModel> providerCandidates(
    AiProviderId provider,
    AiTaskType task,
    AiConfig config, {
    String? preferredModelId,
  }) {
    final Set<AiCapability> need = requirementsFor(task);
    final List<AiModel> pool = <AiModel>[
      for (final AiModel m in ModelRegistry.activeFor(provider))
        if (config.isModelEnabled(m.id) && need.every(m.supports)) m,
    ];
    if (preferredModelId != null) {
      final int i = pool.indexWhere((AiModel m) => m.id == preferredModelId);
      if (i > 0) {
        final AiModel pick = pool.removeAt(i);
        pool.insert(0, pick);
      }
    }
    return pool;
  }
}
