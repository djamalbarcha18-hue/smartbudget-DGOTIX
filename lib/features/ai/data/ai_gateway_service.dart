import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/assistant/domain/ai_conversation.dart';
import 'package:smartbudget/features/ai/domain/ai_errors.dart';
import 'package:smartbudget/features/ai/domain/ai_registry.dart';

/// One answer from the DGOTIX AI gateway (server-side, keys held by the Edge
/// Function). The provider is intentionally NOT exposed.
class GatewayAnswer {
  const GatewayAnswer({
    required this.text,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.fallbackUsed,
  });
  final String text;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final bool fallbackUsed;
}

/// Client for the `ai-gateway` Edge Function. This is the provider-independent
/// path: the app asks DGOTIX AI, the gateway does quota → routing → provider →
/// failover server-side, so no provider key or provider logic lives in the
/// client. Available only when Supabase is configured and the user is signed in.
class AiGatewayService {
  const AiGatewayService();

  Future<GatewayAnswer> ask({
    required AiTaskType task,
    required String prompt,
    required String context,
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    late final FunctionResponse res;
    try {
      res = await Supabase.instance.client.functions.invoke(
        'ai-gateway',
        body: <String, dynamic>{
          'task': task.name,
          'prompt': prompt,
          'context': context,
          // Conversation memory (already trimmed by AiConversation.history);
          // the gateway re-validates and caps it server-side.
          'history': <Map<String, String>>[
            for (final ChatMessage m in history)
              <String, String>{
                'role': m.fromUser ? 'user' : 'assistant',
                'text': m.text,
              },
          ],
        },
      );
    } on FunctionException catch (e) {
      throw _mapFunctionError(e.status, e.details);
    } catch (_) {
      throw const AiFailure(AiErrorKind.providerUnavailable);
    }

    final Object? data = res.data;
    if (data is! Map || data['ok'] != true) {
      throw const AiFailure(AiErrorKind.providerUnavailable);
    }
    final Map<String, dynamic> m = data.cast<String, dynamic>();
    final Object? usage = m['usage'];
    final Map<String, dynamic> u =
        usage is Map ? usage.cast<String, dynamic>() : <String, dynamic>{};
    return GatewayAnswer(
      text: (m['text'] ?? '').toString(),
      model: (m['model'] ?? '').toString(),
      inputTokens: (u['input'] as num?)?.toInt() ?? 0,
      outputTokens: (u['output'] as num?)?.toInt() ?? 0,
      fallbackUsed: m['fallbackUsed'] == true,
    );
  }

  AiFailure _mapFunctionError(int? status, Object? details) {
    final String code =
        details is Map ? (details['error']?.toString() ?? '') : '';
    if (code == 'quota_exceeded' || status == 429) {
      return const AiFailure(AiErrorKind.quotaExceeded);
    }
    if (code == 'missing_token' || code == 'invalid_token' || status == 401) {
      return const AiFailure(AiErrorKind.invalidApiKey);
    }
    // The gateway already hides which provider failed — surface a neutral,
    // retryable "temporarily unavailable".
    return const AiFailure(AiErrorKind.providerUnavailable);
  }
}

final aiGatewayServiceProvider =
    Provider<AiGatewayService>((ref) => const AiGatewayService());
