import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/time/app_clock.dart';
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
///
/// The cache belongs to the account it was saved for: another account
/// signing in on the same device starts on FREE until the server answers.
///
/// The cache also has an age: it carries the time of the last answer, and a
/// paid plan the server has not confirmed for [offlineGrace] stops applying
/// until it does. So a subscription that ended can't stay unlocked on a
/// device that is kept offline.
final entitlementProvider =
    NotifierProvider<EntitlementController, Entitlement>(
        EntitlementController.new);

class EntitlementController extends Notifier<Entitlement> {
  static const String _key = 'sb_entitlement';

  /// How long a cached plan stands in for the server's answer.
  static const Duration offlineGrace = Duration(days: 7);

  /// A saved time this far ahead of now means the clock was moved back.
  static const Duration _clockSlack = Duration(days: 1);

  /// When the plan in [state] was last confirmed (null: never, or FREE).
  DateTime? _checkedAt;

  /// Whether an answer from [checkedAt] is too old (or from the future) to
  /// stand in for the server at [now].
  static bool isStale(DateTime checkedAt, DateTime now) =>
      now.difference(checkedAt) > offlineGrace ||
      checkedAt.difference(now) > _clockSlack;

  /// Set once a plan was pushed in, so the cache read at start can't
  /// replace it.
  bool _pushed = false;

  @override
  Entitlement build() {
    final String? account = ref.watch(currentAccountIdProvider);
    _pushed = false;
    _checkedAt = null;
    _load(account);
    return Entitlement.free;
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> json =
          (jsonDecode(raw) as Map).cast<String, dynamic>();
      // Another account's plan (or one saved before the cache named its
      // account) is never taken over.
      if (json['account'] != account) return;
      // A plan pushed meanwhile (the server's answer) is newer than this.
      if (_pushed) return;
      final DateTime now = AppClock.now();
      final DateTime? checkedAt =
          DateTime.tryParse('${json['checkedAt'] ?? ''}');
      // Too old to trust: FREE until the server answers again.
      if (checkedAt != null && isStale(checkedAt, now)) return;
      state = Entitlement.fromJson(json);
      _checkedAt = checkedAt ?? now;
      // A cache saved before it carried its time starts counting now.
      if (checkedAt == null) _persist();
    } catch (_) {
      // Corrupt cache ⇒ stay on the safe FREE default.
    }
  }

  /// Push the authoritative entitlement from the server/billing layer.
  void hydrate(Entitlement e) {
    _pushed = true;
    _checkedAt = AppClock.now();
    state = e;
    _persist();
  }

  /// Back to FREE when the plan held here was last confirmed too long ago
  /// (the app stayed open, or kept coming back, without the server). The
  /// saved copy is left alone: the next answer replaces it.
  void dropIfStale() {
    final DateTime? at = _checkedAt;
    if (at == null || !isStale(at, AppClock.now())) return;
    _checkedAt = null;
    state = Entitlement.free;
  }

  /// Reset to FREE (e.g. on sign-out). Does not touch the user's data.
  void clear() {
    _pushed = true;
    _checkedAt = null;
    state = Entitlement.free;
    _persistClear();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode(<String, dynamic>{
            ...state.toJson(),
            'account': ref.read(currentAccountIdProvider),
            if (_checkedAt != null)
              'checkedAt': _checkedAt!.toUtc().toIso8601String(),
          }));
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
/// shows the last-known plan instantly; a failed one returns null and leaves
/// the cache as it was.
final remoteEntitlementProvider = FutureProvider<Entitlement?>((ref) async {
  if (!AppEnv.hasSupabase) return null;
  if (!ref.watch(authControllerProvider).isAuthenticated) {
    return Entitlement.free;
  }
  final Entitlement? e = await ref.read(entitlementServiceProvider).fetch();
  // No answer (offline, server down): the last known plan stays in force.
  if (e == null) return null;
  try {
    ref.read(entitlementProvider.notifier).hydrate(e);
  } catch (_) {
    // Cache refresh is best-effort.
  }
  return e;
});

/// Asks the server for the plan again whenever the app comes back into view
/// (a subscription bought, ended or cancelled elsewhere shows up without
/// signing in again), at most once per [EntitlementRefresher.minGap]. The
/// first answer of a session comes from [remoteEntitlementProvider] itself.
/// Its value counts the refreshes asked for.
final entitlementRefreshProvider =
    NotifierProvider<EntitlementRefresher, int>(EntitlementRefresher.new);

class EntitlementRefresher extends Notifier<int> {
  static const Duration minGap = Duration(minutes: 10);

  DateTime? _last;

  @override
  int build() {
    if (!AppEnv.hasSupabase) return 0;
    // Back in view (onShow) is enough: on the web, "resumed" also needs the
    // window to have focus, which a returning user may not give it yet.
    final AppLifecycleListener life =
        AppLifecycleListener(onShow: refresh, onResume: refresh);
    ref.onDispose(life.dispose);
    return 0;
  }

  /// Asks again unless it was asked less than [minGap] ago ([force] skips
  /// that wait).
  void refresh({bool force = false}) {
    final DateTime now = DateTime.now();
    final DateTime? last = _last;
    if (!force && last != null && now.difference(last).abs() < minGap) return;
    _last = now;
    // No answer may come (offline): an old cached plan must not outlive
    // its grace meanwhile.
    ref.read(entitlementProvider.notifier).dropIfStale();
    ref.invalidate(remoteEntitlementProvider);
    state = state + 1;
  }
}

/// The plan actually in force right now (paid plan or an active trial). Prefers
/// the server value once it resolves, falling back to the persisted local cache
/// (which defaults to FREE) so the UI is correct offline and at startup.
/// During the beta ([AppEnv.betaAllAccess]) everyone is on PRO.
final effectivePlanProvider = Provider<Plan>((ref) {
  if (AppEnv.betaAllAccess) return Plan.pro;
  final Entitlement e =
      ref.watch(remoteEntitlementProvider).valueOrNull ??
          ref.watch(entitlementProvider);
  return e.effectivePlanAt(AppClock.now());
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
