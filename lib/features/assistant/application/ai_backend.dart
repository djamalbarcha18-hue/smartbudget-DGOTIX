import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';

/// DGOTIX is the only AI provider: every answer comes from the DGOTIX server
/// gateway (server-held keys, routing, failover) within the plan's quota.
/// Users never bring their own key.
///
/// The gateway can serve a request when a real backend is configured and the
/// user is signed in.
final aiGatewayAvailableProvider = Provider<bool>((ref) {
  return AppEnv.hasSupabase &&
      ref.watch(authControllerProvider).isAuthenticated;
});

/// Whether the assistant chat can run at all.
final assistantReadyProvider = Provider<bool>((ref) {
  return ref.watch(aiGatewayAvailableProvider);
});
