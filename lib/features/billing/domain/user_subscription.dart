/// The user's current subscription snapshot (read from the server's
/// `subscriptions` table via RLS). Display-only; the server is authoritative.
library;

import 'package:smartbudget/features/billing/domain/plan.dart';

class UserSubscription {
  const UserSubscription({
    required this.plan,
    this.provider,
    this.period,
    this.status,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  final Plan plan;
  final String? provider; // 'paddle' | 'paypal'
  final String? period; // 'monthly' | 'yearly'
  final String? status; // 'active' | 'trialing' | 'canceled' | ...
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  /// A paid plan that is currently in force (worth showing a manage card for).
  bool get isPaidActive =>
      plan != Plan.free && (status == 'active' || status == 'trialing');

  static UserSubscription? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final Object? end = row['current_period_end'];
    return UserSubscription(
      plan: PlanX.fromStorage(row['plan'] as String?),
      provider: row['provider'] as String?,
      period: row['period'] as String?,
      status: row['status'] as String?,
      currentPeriodEnd: end == null ? null : DateTime.tryParse('$end'),
      cancelAtPeriodEnd: row['cancel_at_period_end'] == true,
    );
  }
}
