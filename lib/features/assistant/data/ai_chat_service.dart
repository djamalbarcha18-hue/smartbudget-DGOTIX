import 'dart:convert';

import 'package:http/http.dart' as http;

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

/// The answer plus the token usage the provider reported for the call.
class AiChatResult {
  const AiChatResult({required this.text, required this.usage});
  final String text;
  final AiUsage usage;
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

  Future<AiChatResult> _gemini(String key, String model, String system, String q) async {
    final Uri uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
    final String body = await _send(
      uri,
      const <String, String>{'Content-Type': 'application/json'},
      <String, dynamic>{
        'system_instruction': <String, dynamic>{
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
      keyInQuery: true,
    );
    final Map<String, dynamic> data =
        jsonDecode(body) as Map<String, dynamic>;
    final List<dynamic>? cands = data['candidates'] as List<dynamic>?;
    if (cands == null || cands.isEmpty) {
      throw const AiChatException(AiChatError.empty);
    }
    final Map<String, dynamic>? content =
        (cands.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    final String? text = (parts != null && parts.isNotEmpty)
        ? (parts.first as Map<String, dynamic>)['text']?.toString()
        : null;
    final Map<String, dynamic>? um =
        data['usageMetadata'] as Map<String, dynamic>?;
    return AiChatResult(
      text: _requireText(text),
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
    Object body, {
    bool keyInQuery = false,
  }) async {
    http.Response res;
    try {
      res = await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (_) {
      throw const AiChatException(AiChatError.network);
    }
    final int code = res.statusCode;
    if (code == 200) return res.body;
    if (code == 401 || code == 403) {
      throw const AiChatException(AiChatError.invalidKey);
    }
    // Gemini carries the key in the query string; a bad key comes back as 400.
    if (code == 400 && keyInQuery) {
      throw const AiChatException(AiChatError.invalidKey);
    }
    if (code == 429) throw const AiChatException(AiChatError.rateLimited);
    throw AiChatException(AiChatError.unknown, detail: 'HTTP $code');
  }

  String _requireText(String? text) {
    if (text == null || text.trim().isEmpty) {
      throw const AiChatException(AiChatError.empty);
    }
    return text.trim();
  }
}
