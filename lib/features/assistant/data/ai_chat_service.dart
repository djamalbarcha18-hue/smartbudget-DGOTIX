import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smartbudget/features/ai/domain/ai_registry.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';

/// Why an AI request failed, mapped to a friendly localized message by the UI.
enum AiChatError { invalidKey, unsupported, rateLimited, network, empty, unknown }

class AiChatException implements Exception {
  const AiChatException(this.kind, {this.detail});
  final AiChatError kind;
  final String? detail;
  @override
  String toString() => 'AiChatException($kind${detail == null ? '' : ': $detail'})';
}

/// Token usage reported by the provider for one request (null when unknown).
class AiUsage {
  const AiUsage({this.inputTokens, this.outputTokens});
  final int? inputTokens;
  final int? outputTokens;

  int get total => (inputTokens ?? 0) + (outputTokens ?? 0);
}

/// The answer plus the token usage the provider reported for the call, and the
/// model that actually produced it (may differ from the requested one when a
/// fallback was needed).
class AiChatResult {
  const AiChatResult(
      {required this.text, required this.usage, required this.usedModel});
  final String text;
  final AiUsage usage;
  final String usedModel;
}

/// Calls the user's chosen AI provider directly from the browser using their own
/// personal key (BYOK). The key never leaves the device except in this request
/// to the provider the user selected — it is never sent to our servers.
class AiChatService {
  const AiChatService();

  Future<AiChatResult> ask({
    required AiKeyConfig config,
    required String question,
    required String context,
  }) {
    final String system = _systemPrompt(context);
    final String model = config.effectiveModel;
    return switch (config.provider) {
      AiProvider.gemini => _gemini(config.key, model, system, question),
      AiProvider.openai => _openai(config.key, model, system, question),
      AiProvider.anthropic => _anthropic(config.key, model, system, question),
      AiProvider.other => Future<AiChatResult>.error(
          const AiChatException(AiChatError.unsupported)),
    };
  }

  String _systemPrompt(String context) =>
      'You are DGOTIX AI, a concise, practical personal-finance assistant inside '
      "the SmartBudget app. Use the user's real financial context below when it "
      'helps. Be specific and actionable, keep answers short, and never invent '
      "exact figures that aren't provided. Prefer halal-friendly guidance. Reply "
      "in the same language as the user's question (Arabic or English).\n\n"
      'User financial context:\n$context';

  // ---- Providers ----

  /// Tries the requested Gemini model, then falls back to other Gemini models
  /// when the key can't use it (model not found / not supported), so a stale
  /// default never blocks a valid key. Other errors (bad key, rate limit,
  /// network) stop immediately.
  Future<AiChatResult> _gemini(
      String key, String model, String system, String q) async {
    // Candidates come from the registry (active Gemini models only), so a
    // retired id is never tried and new models are picked up automatically.
    final List<String> candidates = <String>[
      model,
      ...ModelRegistry.activeIdsFor(AiProviderId.google),
    ];
    final Set<String> tried = <String>{};
    AiChatException? last;
    for (final String m in candidates) {
      if (m.isEmpty || !tried.add(m)) continue;
      try {
        return await _geminiOnce(key, m, system, q);
      } on AiChatException catch (e) {
        last = e;
        final String d = (e.detail ?? '').toLowerCase();
        final bool modelMissing = e.kind == AiChatError.unknown &&
            (d.contains('not found') ||
                d.contains('not supported') ||
                d.contains('http 404'));
        if (modelMissing) continue; // try the next model
        rethrow; // key / quota / network / other → stop
      }
    }
    throw last ?? const AiChatException(AiChatError.unknown);
  }

  Future<AiChatResult> _geminiOnce(
      String key, String model, String system, String q) async {
    final Uri uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
    final String body = await _send(
      uri,
      const <String, String>{'Content-Type': 'application/json'},
      <String, dynamic>{
        'systemInstruction': <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': system}
          ]
        },
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': q}
            ]
          }
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.4,
          'maxOutputTokens': 800,
        },
      },
    );
    final Map<String, dynamic> data =
        jsonDecode(body) as Map<String, dynamic>;
    final List<dynamic>? cands = data['candidates'] as List<dynamic>?;
    if (cands == null || cands.isEmpty) {
      // No candidates usually means the prompt was blocked; surface the reason.
      final Map<String, dynamic>? fb =
          data['promptFeedback'] as Map<String, dynamic>?;
      final Object? reason = fb?['blockReason'];
      throw AiChatException(AiChatError.empty,
          detail: reason == null ? null : 'Blocked: $reason');
    }
    final Map<String, dynamic> cand0 = cands.first as Map<String, dynamic>;
    final Map<String, dynamic>? content =
        cand0['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    final String? text = (parts != null && parts.isNotEmpty)
        ? (parts.first as Map<String, dynamic>)['text']?.toString()
        : null;
    if (text == null || text.trim().isEmpty) {
      final Object? finish = cand0['finishReason'];
      throw AiChatException(AiChatError.empty,
          detail: finish == null ? null : 'Empty ($finish)');
    }
    final Map<String, dynamic>? um =
        data['usageMetadata'] as Map<String, dynamic>?;
    return AiChatResult(
      text: _requireText(text),
      usedModel: model,
      usage: AiUsage(
        inputTokens: _int(um?['promptTokenCount']),
        outputTokens: _int(um?['candidatesTokenCount']),
      ),
    );
  }

  Future<AiChatResult> _openai(String key, String model, String system, String q) async {
    final Uri uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final String body = await _send(
      uri,
      <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      <String, dynamic>{
        'model': model,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': system},
          <String, String>{'role': 'user', 'content': q},
        ],
        'temperature': 0.4,
        'max_tokens': 800,
      },
    );
    final Map<String, dynamic> data =
        jsonDecode(body) as Map<String, dynamic>;
    final List<dynamic>? choices = data['choices'] as List<dynamic>?;
    final Map<String, dynamic>? msg = (choices != null && choices.isNotEmpty)
        ? (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>?
        : null;
    final Map<String, dynamic>? usage =
        data['usage'] as Map<String, dynamic>?;
    return AiChatResult(
      text: _requireText(msg?['content']?.toString()),
      usedModel: model,
      usage: AiUsage(
        inputTokens: _int(usage?['prompt_tokens']),
        outputTokens: _int(usage?['completion_tokens']),
      ),
    );
  }

  Future<AiChatResult> _anthropic(String key, String model, String system, String q) async {
    final Uri uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final String body = await _send(
      uri,
      <String, String>{
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
        // Required for direct browser (BYOK) calls.
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      <String, dynamic>{
        'model': model,
        'max_tokens': 800,
        'system': system,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'user', 'content': q},
        ],
      },
    );
    final Map<String, dynamic> data =
        jsonDecode(body) as Map<String, dynamic>;
    final List<dynamic>? content = data['content'] as List<dynamic>?;
    final String? text = (content != null && content.isNotEmpty)
        ? (content.first as Map<String, dynamic>)['text']?.toString()
        : null;
    final Map<String, dynamic>? usage =
        data['usage'] as Map<String, dynamic>?;
    return AiChatResult(
      text: _requireText(text),
      usedModel: model,
      usage: AiUsage(
        inputTokens: _int(usage?['input_tokens']),
        outputTokens: _int(usage?['output_tokens']),
      ),
    );
  }

  int? _int(Object? v) => v is num ? v.toInt() : null;

  // ---- Shared HTTP + error mapping ----

  Future<String> _send(
    Uri uri,
    Map<String, String> headers,
    Object body,
  ) async {
    http.Response res;
    try {
      res = await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (_) {
      throw const AiChatException(AiChatError.network);
    }
    final int code = res.statusCode;
    if (code == 200) return res.body;

    // Surface the provider's own error text so failures are diagnosable and
    // classified correctly (a wrong model, a disabled API, an invalid key…).
    final String msg = _extractError(res.body);
    final String? detail = msg.isEmpty ? 'HTTP $code' : msg;
    if (code == 429) {
      throw AiChatException(AiChatError.rateLimited, detail: detail);
    }
    final String low = msg.toLowerCase();
    final bool keyish = code == 401 ||
        code == 403 ||
        low.contains('api key') ||
        low.contains('api_key_invalid') ||
        low.contains('permission');
    if (keyish) {
      throw AiChatException(AiChatError.invalidKey, detail: detail);
    }
    throw AiChatException(AiChatError.unknown, detail: detail);
  }

  /// Pulls a human-readable message out of a provider error body
  /// ({"error":{"message":"…"}} for OpenAI/Gemini/Anthropic).
  String _extractError(String body) {
    try {
      final Object? d = jsonDecode(body);
      if (d is Map) {
        final Object? err = d['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (err is String) return err;
      }
    } catch (_) {
      // Non-JSON body; ignore.
    }
    return '';
  }

  String _requireText(String? text) {
    if (text == null || text.trim().isEmpty) {
      throw const AiChatException(AiChatError.empty);
    }
    return text.trim();
  }
}
