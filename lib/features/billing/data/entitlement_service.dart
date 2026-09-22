import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/features/billing/domain/entitlement.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';

/// Reads the signed-in user's entitlement (plan + trial) from Supabase.
///
/// The server is the source of truth; this only reads. RLS (see
/// supabase/ai_gateway.sql) lets a user read only their own `ai_entitlements`
/// row. Any failure returns [Entitlement.free] rather than throwing — an
/// entitlement lookup must never block the app or degrade core features.
class EntitlementService {
  const EntitlementService();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  Future<Entitlement> fetch() async {
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
      );
    } catch (_) {
      return Entitlement.free;
    }
  }
}

final entitlementServiceProvider =
    Provider<EntitlementService>((_) => const EntitlementService());
