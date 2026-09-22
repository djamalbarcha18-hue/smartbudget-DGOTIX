import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/billing/domain/user_subscription.dart';

/// Reads the signed-in user's subscription and fetches a management URL. All
/// reads go through RLS (a user sees only their own row); the management URL
/// comes from a server function so no provider key touches the client. Never
/// throws to the UI.
class SubscriptionService {
  const SubscriptionService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserSubscription?> fetch() async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return null;
    try {
      final Map<String, dynamic>? row = await _client
          .from('subscriptions')
          .select(
              'provider, plan, period, status, current_period_end, cancel_at_period_end')
          .eq('user_id', uid)
          .maybeSingle();
      return UserSubscription.fromRow(row);
    } catch (_) {
      return null;
    }
  }

  /// A URL where the user can manage/cancel, or null if unavailable.
  Future<String?> manageUrl() async {
    try {
      final FunctionResponse res =
          await _client.functions.invoke('manage-subscription');
      final Object? data = res.data;
      if (data is Map && data['url'] is String) return data['url'] as String;
      return null;
    } catch (_) {
      return null;
    }
  }
}

final subscriptionServiceProvider =
    Provider<SubscriptionService>((_) => const SubscriptionService());

/// The current subscription, or null when there's none / signed out.
final subscriptionProvider = FutureProvider<UserSubscription?>((ref) async {
  return ref.read(subscriptionServiceProvider).fetch();
});
