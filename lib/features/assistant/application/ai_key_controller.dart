import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The AI provider a personal key belongs to. Kept generic so users can bring a
/// key from whichever service they have an account with.
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
}

/// The user's personal AI key configuration. The key is a personal secret owned
/// solely by the user; see [AiKeyController] for how it is stored.
class AiKeyConfig {
  const AiKeyConfig({required this.provider, required this.key});
  final AiProvider provider;
  final String key;

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
      state = AiKeyConfig(
        provider: AiProviderX.fromStorage(p.getString(_providerKey)),
        key: secret,
      );
    } catch (_) {
      // Keep null (not connected).
    }
  }

  /// Saves and activates a personal key on THIS device only.
  Future<void> save(AiProvider provider, String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return;
    state = AiKeyConfig(provider: provider, key: trimmed);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_secretKey, trimmed);
      await p.setString(_providerKey, provider.storageId);
    } catch (_) {
      // Non-fatal; state still reflects the session.
    }
  }

  /// Removes the key from the device entirely.
  Future<void> remove() async {
    state = null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(_secretKey);
      await p.remove(_providerKey);
    } catch (_) {
      // Non-fatal.
    }
  }
}
