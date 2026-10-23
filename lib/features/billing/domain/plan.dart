/// SmartBudget subscription plans — the tier ladder.
///
/// This is the ONE place plan identity and ordering live. Feature gating never
/// writes `if (plan == pro)`; it compares ranks (`plan.atLeast(minTier)`) so a
/// new tier inserted in the middle keeps every gate correct. Prices here are
/// display placeholders (the billing provider is the source of truth at
/// checkout); quotas live in the feature catalog, not here.
library;

/// Ordered from least to most capable. Rank is the `index`, so higher = more.
/// Insert new tiers in rank order; never reorder existing values.
///
/// Two plans: FREE and PREMIUM. Premium keeps the storage id `pro` (the
/// server, the database and the billing price map all say `pro`); the old
/// BASIC plan was merged into it, so a stored `basic` reads as Premium.
enum Plan {
  free,
  pro,
}

/// A billing period for a paid plan.
enum BillingPeriod { monthly, yearly }

extension PlanX on Plan {
  /// Stable id for storage / server payloads. Never localize this.
  String get storageId => name;

  static Plan fromStorage(String? id) {
    for (final Plan p in Plan.values) {
      if (p.name == id) return p;
    }
    if (id == 'basic') return Plan.pro; // merged into Premium
    return Plan.free; // safe default: unknown/unset ⇒ free tier
  }

  /// True when this plan is at least as capable as [other] (rank compare).
  bool atLeast(Plan other) => index >= other.index;

  bool get isPaid => this != Plan.free;

  /// Non-localized label for diagnostics. UI uses l10n, not this.
  String get label => switch (this) {
        Plan.free => 'FREE',
        Plan.pro => 'PREMIUM',
      };

  /// Display price in USD for a period, or null when the plan has no such
  /// option (FREE has no paid period). These mirror docs/PRICING.md and are for
  /// display only — the billing provider is authoritative at checkout.
  double? priceUsd(BillingPeriod period) => switch ((this, period)) {
        (Plan.free, _) => 0.0,
        (Plan.pro, BillingPeriod.monthly) => 7.99,
        (Plan.pro, BillingPeriod.yearly) => 49.99,
      };
}
