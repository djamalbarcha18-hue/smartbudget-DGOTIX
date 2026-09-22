import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/ai/domain/ai_registry.dart';

/// The AI provider a personal key belongs to. Kept generic so users can bring a
/// key from whichever service they have an account with. Model lists and prices
/// come from [ModelRegistry] (the single source of truth) — never hardcoded.
enum AiProvider { openai, anthropic, gemini, other }

extension AiProviderX on AiProvider {
  String get storageId => switch (this) {
        AiProvider.openai => 'openai',
        AiProvider.anthropic => 'anthropic',
        AiProvider.gemini => 'gemini',
        AiProvider.other => 'other',
      };

  static AiProvider fromStorage(String? id) => switch (id) {
        'openai' => AiProvider.openai,
        'anthropic' => AiProvider.anthropic,
        'gemini' => AiProvider.gemini,
        _ => AiProvider.other,
      };

  /// A short label for the provider (product names are proper nouns, so they
  /// stay the same in every language).
  String get label => switch (this) {
        AiProvider.openai => 'OpenAI',
        AiProvider.anthropic => 'Anthropic (Claude)',
        AiProvider.gemini => 'Google Gemini',
        AiProvider.other => 'Other',
      };

  /// The provider's own console/page where the user can create or copy their
  /// personal API key, or null when there is no well-known page (Other).
  String? get consoleUrl => switch (this) {
        AiProvider.openai => 'https://platform.openai.com/api-keys',
        AiProvider.anthropic => 'https://console.anthropic.com/settings/keys',
        AiProvider.gemini => 'https://aistudio.google.com/apikey',
        AiProvider.other => null,
      };

  /// Short name of where the key comes from, used on the "get a key" button.
  String get consoleName => switch (this) {
        AiProvider.openai => 'OpenAI',
        AiProvider.anthropic => 'Anthropic',
        AiProvider.gemini => 'Google',
        AiProvider.other => '',
      };

  /// Maps to the registry's provider id (null for [AiProvider.other]).
  AiProviderId? get providerId => switch (this) {
        AiProvider.openai => AiProviderId.openai,
        AiProvider.anthropic => AiProviderId.anthropic,
        AiProvider.gemini => AiProviderId.google,
        AiProvider.other => null,
      };

  /// Selectable ACTIVE models for this provider, from the registry (source of
  /// truth) — retired ids are never offered.
  List<String> get models {
    final AiProviderId? pid = providerId;
    return pid == null ? const <String>[] : ModelRegistry.activeIdsFor(pid);
  }

  /// The provider's default model (empty for [AiProvider.other]).
  String get defaultModel {
    final AiProviderId? pid = providerId;
    return pid == null ? '' : ModelRegistry.defaultIdFor(pid);
  }
}

/// The user's personal AI key configuration. The key is a personal secret owned
/// solely by the user; see [AiKeyController] for how it is stored.
class AiKeyConfig {
  const AiKeyConfig({required this.provider, required this.key, this.model});
  final AiProvider provider;
  final String key;

  /// The chosen model id, or null to use the provider's default.
  final String? model;

  /// The model actually used for requests (chosen model, or provider default).
  String get effectiveModel =>
      (model != null && model!.isNotEmpty) ? model! : provider.defaultModel;

  bool get isSet => key.trim().isNotEmpty;

  /// A masked form for display (never shows the full secret), e.g. "sk-…7f2a".
  String get masked {
    final String k = key.trim();
    if (k.length <= 8) return '••••';
    return '${k.substring(0, 3)}…${k.substring(k.length - 4)}';
  }
}

/// Whether a personal AI key is currently connected (activated).
final aiKeyConnectedProvider = Provider<bool>((ref) {
  final AiKeyConfig? cfg = ref.watch(aiKeyProvider);
  return cfg?.isSet ?? false;
});

/// Bring-Your-Own-Key store for the DGOTIX AI assistant.
///
/// PRIVACY: the key is a personal secret that belongs to the user alone. It is
/// stored ONLY on this device (local storage) and is never transmitted to
/// SmartBudget / DGoTiX servers, nor used for anything other than the user's own
/// AI requests. The user can remove it at any time, which erases it from the
/// device.
final aiKeyProvider =
    NotifierProvider<AiKeyController, AiKeyConfig?>(AiKeyController.new);

class AiKeyController extends Notifier<AiKeyConfig?> {
  static const String _providerKey = 'sb_ai_provider';
  static const String _secretKey = 'sb_ai_key';
  static const String _modelKey = 'sb_ai_model';

  @override
  AiKeyConfig? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? secret = p.getString(_secretKey);
      if (secret == null || secret.trim().isEmpty) return;
      final AiProvider provider =
          AiProviderX.fromStorage(p.getString(_providerKey));
      final String? storedModel = p.getString(_modelKey);

      // Migrate a retired/unknown stored model id to a live replacement (e.g.
      // gemini-2.0-flash → gemini-flash-latest) so a stale setting can't 404.
      String? model = storedModel;
      final AiProviderId? pid = provider.providerId;
      if (pid != null && storedModel != null && storedModel.isNotEmpty) {
        final String resolved =
            ModelRegistry.resolveUsableId(pid, storedModel);
        if (resolved.isNotEmpty && resolved != storedModel) {
          model = resolved;
          await p.setString(_modelKey, resolved);
        }
      }

      state = AiKeyConfig(provider: provider, key: secret, model: model);
    } catch (_) {
      // Keep null (not connected).
    }
  }

  /// Saves and activates a personal key (and optional model) on THIS device.
  Future<void> save(AiProvider provider, String key, {String? model}) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return;
    state = AiKeyConfig(provider: provider, key: trimmed, model: model);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_secretKey, trimmed);
      await p.setString(_providerKey, provider.storageId);
      if (model != null && model.isNotEmpty) {
        await p.setString(_modelKey, model);
      } else {
        await p.remove(_modelKey);
      }
    } catch (_) {
      // Non-fatal; state still reflects the session.
    }
  }

  /// Changes only the model for an already-connected key (persisted).
  Future<void> setModel(String model) async {
    final AiKeyConfig? cur = state;
    if (cur == null) return;
    state = AiKeyConfig(provider: cur.provider, key: cur.key, model: model);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_modelKey, model);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Removes the key from the device entirely.
  Future<void> remove() async {
    state = null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(_secretKey);
      await p.remove(_providerKey);
      await p.remove(_modelKey);
    } catch (_) {
      // Non-fatal.
    }
  }
}
