import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/features/ai/domain/ai_quota.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';

/// The allowance as the server last reported it (with every answer, with a
/// refusal, or when the assistant opens). Null until the server has said, and
/// again after signing out or in as someone else.
final aiServerQuotaProvider =
    NotifierProvider<AiServerQuotaController, AiQuotaInfo?>(
        AiServerQuotaController.new);

class AiServerQuotaController extends Notifier<AiQuotaInfo?> {
  @override
  AiQuotaInfo? build() {
    ref.watch(currentAccountIdProvider);
    return null;
  }

  void set(AiQuotaInfo? q) {
    if (q != null) state = q;
  }
}
