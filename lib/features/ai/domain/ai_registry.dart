/// DGOTIX AI — provider/model source of truth.
///
/// This is the ONE place model IDs, capabilities, pricing and deprecation live.
/// Widgets, pricing and routing all read from here — never hardcode a model id
/// elsewhere. Provider selection stays behind [AiProviderId]; there is no
/// `if (provider == gemini)` scattered across the app.
///
/// Model facts verified against Google's official Gemini API docs (Sept 2026):
/// Gemini 1.0 / 1.5 and 2.0 (Flash & Flash-Lite) are SHUT DOWN and now return
/// 404. Active line is Gemini 2.5 and 3.x; `gemini-flash-latest` /
/// `gemini-flash-lite-latest` are stable aliases that auto-track the newest
/// Flash, which is why they are the defaults (deprecation-proof).
library;

enum AiProviderId { google, openai, anthropic }

extension AiProviderIdX on AiProviderId {
  String get storageId => name;
  static AiProviderId? fromStorage(String? id) {
    for (final AiProviderId p in AiProviderId.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  String get displayName => switch (this) {
        AiProviderId.google => 'Google Gemini',
        AiProviderId.openai => 'OpenAI',
        AiProviderId.anthropic => 'Anthropic (Claude)',
      };

  /// Where the user creates/copies a personal key.
  String? get consoleUrl => switch (this) {
        AiProviderId.google => 'https://aistudio.google.com/apikey',
        AiProviderId.openai => 'https://platform.openai.com/api-keys',
        AiProviderId.anthropic => 'https://console.anthropic.com/settings/keys',
      };

  String get consoleName => switch (this) {
        AiProviderId.google => 'Google',
        AiProviderId.openai => 'OpenAI',
        AiProviderId.anthropic => 'Anthropic',
      };
}

enum AiCapability { text, image, structuredOutput, streaming }

enum AiModelStatus { stable, preview, deprecated, shutdown }

/// The kinds of AI work in the app. Routing is per task so each can pick the
/// cheapest capable model and its own fallbacks.
enum AiTaskType {
  chat,
  analysis,
  financialInsight,
  report,
  receiptScan,
  receiptRetry,
}

/// One model, with everything the router and the cost meter need.
class AiModel {
  const AiModel({
    required this.provider,
    required this.id,
    required this.displayName,
    required this.status,
    required this.capabilities,
    required this.inputPer1M,
    required this.outputPer1M,
    this.maxOutputTokens = 800,
    this.priority = 100,
    this.replacementId,
    this.deprecatedAt,
    this.shutdownAt,
  });

  final AiProviderId provider;
  final String id;
  final String displayName;
  final AiModelStatus status;
  final Set<AiCapability> capabilities;

  /// Approximate USD price per 1,000,000 tokens (estimate; user-overridable).
  final double inputPer1M;
  final double outputPer1M;

  final int maxOutputTokens;

  /// Lower = preferred. Used to pick a default and order fallbacks.
  final int priority;

  /// For a retired model, the id that replaces it (used by migration & routing).
  final String? replacementId;
  final String? deprecatedAt; // YYYY-MM (informational)
  final String? shutdownAt; // YYYY-MM (informational)

  /// Usable right now (not retired). Aliases and GA/preview models are usable.
  bool get isActive =>
      status == AiModelStatus.stable || status == AiModelStatus.preview;

  bool supports(AiCapability c) => capabilities.contains(c);
  bool get supportsImage => capabilities.contains(AiCapability.image);
  bool get supportsStructured =>
      capabilities.contains(AiCapability.structuredOutput);
  bool get supportsStreaming => capabilities.contains(AiCapability.streaming);
}

/// The registry: static source of truth + queries.
abstract final class ModelRegistry {
  static const Set<AiCapability> _multimodal = <AiCapability>{
    AiCapability.text,
    AiCapability.image,
    AiCapability.structuredOutput,
    AiCapability.streaming,
  };
  static const Set<AiCapability> _textOnly = <AiCapability>{
    AiCapability.text,
    AiCapability.structuredOutput,
    AiCapability.streaming,
  };

  static const List<AiModel> all = <AiModel>[
    // ---------------- Google Gemini (generativelanguage API) ----------------
    // Stable aliases that always track the newest Flash → deprecation-proof
    // defaults. (Google gives a 2-week email notice before breaking changes.)
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-flash-latest',
      displayName: 'Gemini Flash (latest)',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.75,
      outputPer1M: 3.75,
      priority: 1,
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-flash-lite-latest',
      displayName: 'Gemini Flash-Lite (latest)',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.10,
      outputPer1M: 0.40,
      priority: 4,
    ),
    // Pinned current GA models (Sept 2026).
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-3.8-flash',
      displayName: 'Gemini 3.8 Flash',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.75,
      outputPer1M: 3.75,
      priority: 2,
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.30, // approximate
      outputPer1M: 2.50, // approximate
      priority: 3,
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-2.5-flash-lite',
      displayName: 'Gemini 2.5 Flash-Lite',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.10,
      outputPer1M: 0.40,
      priority: 5,
    ),
    // Retired — kept only so migration can map stored ids to a replacement.
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash (retired)',
      status: AiModelStatus.shutdown,
      capabilities: _multimodal,
      inputPer1M: 0.10,
      outputPer1M: 0.40,
      shutdownAt: '2026-06',
      replacementId: 'gemini-flash-latest',
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-2.0-flash-lite',
      displayName: 'Gemini 2.0 Flash-Lite (retired)',
      status: AiModelStatus.shutdown,
      capabilities: _multimodal,
      inputPer1M: 0.075,
      outputPer1M: 0.30,
      shutdownAt: '2026-06',
      replacementId: 'gemini-flash-lite-latest',
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash (retired)',
      status: AiModelStatus.shutdown,
      capabilities: _multimodal,
      inputPer1M: 0.075,
      outputPer1M: 0.30,
      shutdownAt: '2025',
      replacementId: 'gemini-flash-latest',
    ),
    AiModel(
      provider: AiProviderId.google,
      id: 'gemini-1.5-pro',
      displayName: 'Gemini 1.5 Pro (retired)',
      status: AiModelStatus.shutdown,
      capabilities: _multimodal,
      inputPer1M: 1.25,
      outputPer1M: 5.0,
      shutdownAt: '2025',
      replacementId: 'gemini-flash-latest',
    ),

    // ---------------- OpenAI ----------------
    // NOTE: not re-verified in this audit (Gemini was the priority). IDs are
    // the previously-used ones; verify against OpenAI docs before relying on
    // exact availability/pricing.
    AiModel(
      provider: AiProviderId.openai,
      id: 'gpt-4o-mini',
      displayName: 'GPT-4o mini',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.15,
      outputPer1M: 0.60,
      priority: 1,
    ),
    AiModel(
      provider: AiProviderId.openai,
      id: 'gpt-4o',
      displayName: 'GPT-4o',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 2.50,
      outputPer1M: 10.0,
      priority: 3,
    ),
    AiModel(
      provider: AiProviderId.openai,
      id: 'gpt-4.1-mini',
      displayName: 'GPT-4.1 mini',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 0.40,
      outputPer1M: 1.60,
      priority: 2,
    ),

    // ---------------- Anthropic ----------------
    // NOTE: not re-verified in this audit.
    AiModel(
      provider: AiProviderId.anthropic,
      id: 'claude-3-5-haiku-latest',
      displayName: 'Claude 3.5 Haiku',
      status: AiModelStatus.stable,
      capabilities: _textOnly,
      inputPer1M: 0.80,
      outputPer1M: 4.0,
      priority: 1,
    ),
    AiModel(
      provider: AiProviderId.anthropic,
      id: 'claude-3-5-sonnet-latest',
      displayName: 'Claude 3.5 Sonnet',
      status: AiModelStatus.stable,
      capabilities: _multimodal,
      inputPer1M: 3.0,
      outputPer1M: 15.0,
      priority: 2,
    ),
  ];

  static AiModel? byId(String id) {
    for (final AiModel m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Active models for a provider, best (lowest priority number) first.
  static List<AiModel> activeFor(AiProviderId provider) {
    final List<AiModel> out = <AiModel>[
      for (final AiModel m in all)
        if (m.provider == provider && m.isActive) m,
    ]..sort((AiModel a, AiModel b) => a.priority.compareTo(b.priority));
    return out;
  }

  static List<String> activeIdsFor(AiProviderId provider) =>
      <String>[for (final AiModel m in activeFor(provider)) m.id];

  /// The provider's default model id (highest priority active), or '' if none.
  static String defaultIdFor(AiProviderId provider) {
    final List<AiModel> a = activeFor(provider);
    return a.isEmpty ? '' : a.first.id;
  }

  /// Maps a (possibly retired/unknown) stored model id to one to actually use:
  /// itself if active, its declared replacement, else the provider default.
  static String resolveUsableId(AiProviderId provider, String? storedId) {
    if (storedId == null || storedId.isEmpty) return defaultIdFor(provider);
    final AiModel? m = byId(storedId);
    if (m != null && m.isActive) return storedId;
    if (m?.replacementId != null) {
      final AiModel? r = byId(m!.replacementId!);
      if (r != null && r.isActive) return r.id;
    }
    return defaultIdFor(provider);
  }
}
