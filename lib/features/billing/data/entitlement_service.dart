import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// Reads the signed-in user's entitlement (plan + trial + billing period) from
/// Supabase.
///
/// The server is the source of truth; this only reads. RLS (see
/// supabase/ai_gateway.sql) lets a user read only their own `ai_entitlements`
/// row. It never throws: a lookup must never block the app. A failed lookup
/// (offline, server down) gives null — not FREE — so a paying user keeps
/// the last known plan instead of losing it until the next good answer.
class EntitlementService {
  const EntitlementService();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  Future<Entitlement?> fetch() async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return Entitlement.free;
    try {
      final Map<String, dynamic>? row = await _client
          .from('ai_entitlements')
          .select('plan, trial_plan, trial_expires_at')
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return Entitlement.free;
      final String? tp = row['trial_plan'] as String?;
      final Object? te = row['trial_expires_at'];
      return Entitlement(
        plan: PlanX.fromStorage(row['plan'] as String?),
        trialPlan: tp == null ? null : PlanX.fromStorage(tp),
        trialExpiresAt: te == null ? null : DateTime.tryParse('$te'),
        period: await _period(uid),
        trialUsed: await _trialUsed(uid),
      );
    } catch (_) {
      return null;
    }
  }

  /// Whether the account has had its free trial. Read on its own: a database
  /// without supabase/launch_offers.sql has no such column, and that must not
  /// cost the plan. Unknown ⇒ true, so no trial is offered that can't start.
  Future<bool> _trialUsed(String uid) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('ai_entitlements')
          .select('trial_used_at')
          .eq('user_id', uid)
          .maybeSingle();
      return row?['trial_used_at'] != null;
    } catch (_) {
      return true;
    }
  }

  /// The billing period of the user's subscription (RLS: own row only, see
  /// supabase/billing.sql). Unknown ⇒ null, which simply withholds the
  /// yearly-only perks — it never blocks anything else.
  Future<BillingPeriod?> _period(String uid) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('subscriptions')
          .select('period')
          .eq('user_id', uid)
          .maybeSingle();
      return Entitlement.billingPeriodFrom(row?['period'] as String?);
    } catch (_) {
      return null;
    }
  }
}

final entitlementServiceProvider =
    Provider<EntitlementService>((_) => const EntitlementService());
