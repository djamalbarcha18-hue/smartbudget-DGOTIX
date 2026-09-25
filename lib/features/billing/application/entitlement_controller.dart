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

/// The authoritative entitlement from the server:
/// - backend configured + signed in → the user's row from the server;
/// - backend configured + signed out → FREE (never trust a stale cache);
/// - no backend at all (local demo) → null, meaning "no server answer", so
///   the local cache applies (which the developer plan preview can set).
/// A successful fetch also refreshes the local cache so the next cold start
/// shows the last-known plan instantly.
final remoteEntitlementProvider = FutureProvider<Entitlement?>((ref) async {
  if (!AppEnv.hasSupabase) return null;
  if (!ref.watch(authControllerProvider).isAuthenticated) {
    return Entitlement.free;
  }
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
/// During the beta ([AppEnv.betaAllAccess]) everyone is on PRO.
final effectivePlanProvider = Provider<Plan>((ref) {
  if (AppEnv.betaAllAccess) return Plan.pro;
  final Entitlement e =
      ref.watch(remoteEntitlementProvider).valueOrNull ??
          ref.watch(entitlementProvider);
  return e.effectivePlanAt(DateTime.now());
});

/// How the account's paid plan is billed (null on FREE or when unknown).
/// During the beta it is yearly, so yearly-only extras are unlocked too.
final billingPeriodProvider = Provider<BillingPeriod?>((ref) {
  if (AppEnv.betaAllAccess) return BillingPeriod.yearly;
  final Entitlement e =
      ref.watch(remoteEntitlementProvider).valueOrNull ??
          ref.watch(entitlementProvider);
  return e.paidPeriod;
});
