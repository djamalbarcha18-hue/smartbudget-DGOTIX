import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';

/// Which backend answers DGOTIX AI.
enum AiBackend { byok, gateway }

/// The one rule for who answers (pure, so it's testable): a personal key only
/// counts on a plan that allows it (PRO); otherwise the server gateway with
/// the plan's quota, when it's available; otherwise nothing yet.
abstract final class AiBackendRules {
  static AiBackend? choose({
    required bool keyConnected,
    required bool byokAllowed,
    required bool gatewayAvailable,
  }) {
    if (keyConnected && byokAllowed) return AiBackend.byok;
    if (gatewayAvailable) return AiBackend.gateway;
    return null;
  }
}

/// Whether the account's plan allows a personal AI key (PRO).
final byokAllowedProvider = Provider<bool>((ref) {
  return ref.watch(featureGateProvider(Feature.byok)).allowed;
});

/// The server gateway can serve a request when a real backend is configured and
/// the user is signed in (it uses server-held keys + per-user quota).
final aiGatewayAvailableProvider = Provider<bool>((ref) {
  return AppEnv.hasSupabase &&
      ref.watch(authControllerProvider).isAuthenticated;
});

/// The chosen backend (see [AiBackendRules]).
final aiBackendProvider = Provider<AiBackend?>((ref) {
  return AiBackendRules.choose(
    keyConnected: ref.watch(aiKeyConnectedProvider),
    byokAllowed: ref.watch(byokAllowedProvider),
    gatewayAvailable: ref.watch(aiGatewayAvailableProvider),
  );
});

/// Whether the assistant chat can run at all (personal key OR gateway).
final assistantReadyProvider = Provider<bool>((ref) {
  return ref.watch(aiBackendProvider) != null;
});
