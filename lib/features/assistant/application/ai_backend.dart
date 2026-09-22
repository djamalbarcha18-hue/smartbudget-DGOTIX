import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';

/// Which backend answers DGOTIX AI.
enum AiBackend { byok, gateway }

/// The server gateway can serve a request when a real backend is configured and
/// the user is signed in (it uses server-held keys + per-user quota).
final aiGatewayAvailableProvider = Provider<bool>((ref) {
  return AppEnv.hasSupabase &&
      ref.watch(authControllerProvider).isAuthenticated;
});

/// The chosen backend: a connected personal key wins (the user opted in with
/// their own key/quota); otherwise the server gateway if available.
final aiBackendProvider = Provider<AiBackend?>((ref) {
  final bool byok = ref.watch(aiKeyConnectedProvider);
  if (byok) return AiBackend.byok;
  if (ref.watch(aiGatewayAvailableProvider)) return AiBackend.gateway;
  return null; // no way to answer yet
});

/// Whether the assistant chat can run at all (personal key OR gateway).
final assistantReadyProvider = Provider<bool>((ref) {
  return ref.watch(aiBackendProvider) != null;
});
