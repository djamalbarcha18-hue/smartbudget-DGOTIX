import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/ai/domain/ai_registry.dart';

/// Runtime AI configuration: the kill switches and failover policy.
///
/// Providers and models can be turned off here WITHOUT touching widget code or
/// shipping a new build. [mergeRemote] is the hook to apply an owner-controlled
/// remote config (e.g. a JSON file fetched at startup) so an outage can be
/// handled by flipping a flag centrally — see docs/AI_ARCHITECTURE for the
/// server-side stage. Local overrides persist per device.
class AiConfig {
  const AiConfig({
    this.disabledProviders = const <AiProviderId>{},
    this.disabledModels = const <String>{},
    this.maxFallbackAttempts = 2,
  });

  /// Providers turned off (kill switch) — no request is ever sent to them.
  final Set<AiProviderId> disabledProviders;

  /// Individual models turned off (model kill switch).
  final Set<String> disabledModels;

  /// How many *additional* models/providers may be tried after the primary on a
  /// retryable failure.
  final int maxFallbackAttempts;

  bool isProviderEnabled(AiProviderId p) => !disabledProviders.contains(p);
  bool isModelEnabled(String id) => !disabledModels.contains(id);

  AiConfig copyWith({
    Set<AiProviderId>? disabledProviders,
    Set<String>? disabledModels,
    int? maxFallbackAttempts,
  }) =>
      AiConfig(
        disabledProviders: disabledProviders ?? this.disabledProviders,
        disabledModels: disabledModels ?? this.disabledModels,
        maxFallbackAttempts: maxFallbackAttempts ?? this.maxFallbackAttempts,
      );

  /// Applies an owner/remote config (safe subset). Unknown keys are ignored so
  /// an old client never breaks on a newer config.
  AiConfig mergeRemote(Map<String, dynamic> json) {
    Set<AiProviderId> provs = disabledProviders;
    Set<String> models = disabledModels;
    int maxFb = maxFallbackAttempts;
    final Object? dp = json['disabledProviders'];
    if (dp is List) {
      provs = <AiProviderId>{
        for (final Object? e in dp)
          if (AiProviderIdX.fromStorage(e?.toString()) case final AiProviderId p)
            p,
      };
    }
    final Object? dm = json['disabledModels'];
    if (dm is List) {
      models = <String>{for (final Object? e in dm) e.toString()};
    }
    final Object? mf = json['maxFallbackAttempts'];
    if (mf is num) maxFb = mf.toInt().clamp(0, 5);
    return AiConfig(
      disabledProviders: provs,
      disabledModels: models,
      maxFallbackAttempts: maxFb,
    );
  }
}

/// Persisted, owner-adjustable AI config (kill switches + policy).
final aiConfigProvider =
    NotifierProvider<AiConfigController, AiConfig>(AiConfigController.new);

class AiConfigController extends Notifier<AiConfig> {
  static const String _key = 'sb_ai_config';

  @override
  AiConfig build() {
    _load();
    return const AiConfig();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = const AiConfig()
          .mergeRemote(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Keep defaults.
    }
  }

  void setProviderEnabled(AiProviderId p, bool enabled) {
    final Set<AiProviderId> next = <AiProviderId>{...state.disabledProviders};
    if (enabled) {
      next.remove(p);
    } else {
      next.add(p);
    }
    state = state.copyWith(disabledProviders: next);
    _persist();
  }

  void setModelEnabled(String id, bool enabled) {
    final Set<String> next = <String>{...state.disabledModels};
    if (enabled) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(disabledModels: next);
    _persist();
  }

  void setMaxFallbackAttempts(int n) {
    state = state.copyWith(maxFallbackAttempts: n.clamp(0, 5));
    _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode(<String, dynamic>{
            'disabledProviders': <String>[
              for (final AiProviderId x in state.disabledProviders) x.name,
            ],
            'disabledModels': state.disabledModels.toList(),
            'maxFallbackAttempts': state.maxFallbackAttempts,
          }));
    } catch (_) {
      // Non-fatal.
    }
  }
}
