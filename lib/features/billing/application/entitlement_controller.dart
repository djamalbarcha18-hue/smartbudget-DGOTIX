import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/data/entitlement_service.dart';
import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// The account's current entitlement.
///
/// The **server is the source of truth**. This controller holds a local cache:
/// it defaults to [Entitlement.free] (nothing paid unlocked without server
/// truth), persists the last known entitlement so the UI is stable across
/// restarts, and exposes [hydrate] for the server/billing layer to push the
/// authoritative value in. It never *grants* a paid plan on its own.
final entitlementProvider =
    NotifierProvider<EntitlementController, Entitlement>(
        EntitlementController.new);

class EntitlementController extends Notifier<Entitlement> {
  static const String _key = 'sb_entitlement';

  @override
  Entitlement build() {
    _load();
    return Entitlement.free;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = Entitlement.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      // Corrupt cache ⇒ stay on the safe FREE default.
    }
  }

  /// Push the authoritative entitlement from the server/billing layer.
  void hydrate(Entitlement e) {
    state = e;
    _persist();
  }

  /// Reset to FREE (e.g. on sign-out). Does not touch the user's data.
  void clear() {
    state = Entitlement.free;
    _persistClear();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> _persistClear() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The authoritative entitlement fetched from the server, when the user is
/// signed in and a backend is configured; otherwise [Entitlement.free]. On a
/// successful fetch it also refreshes the local cache so the next cold start
/// shows the last-known plan instantly.
final remoteEntitlementProvider = FutureProvider<Entitlement>((ref) async {
  final bool available =
      AppEnv.hasSupabase && ref.watch(authControllerProvider).isAuthenticated;
  if (!available) return Entitlement.free;
  final Entitlement e = await ref.read(entitlementServiceProvider).fetch();
  try {
    ref.read(entitlementProvider.notifier).hydrate(e);
  } catch (_) {
    // Cache refresh is best-effort.
  }
  return e;
});

/// The plan actually in force right now (paid plan or an active trial). Prefers
/// the server value once it resolves, falling back to the persisted local cache
/// (which defaults to FREE) so the UI is correct offline and at startup.
final effectivePlanProvider = Provider<Plan>((ref) {
  final Entitlement e =
      ref.watch(remoteEntitlementProvider).valueOrNull ??
          ref.watch(entitlementProvider);
  return e.effectivePlanAt(DateTime.now());
});
