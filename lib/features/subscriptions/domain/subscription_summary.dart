import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_cancel.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription_schedule.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// What the subscriptions cost and where they stand (pure: no Flutter, no
/// IO).
class SubscriptionSummary {
  const SubscriptionSummary({
    required this.base,
    required this.monthly,
    required this.yearly,
    required this.estimated,
    required this.missingRates,
    required this.active,
    required this.renewingSoon,
    required this.toCancel,
    required this.ended,
    required this.byCard,
  });

  /// The currency of the totals (the user's base currency).
  final String base;

  /// What the subscriptions still charged cost a month and a year, in
  /// [base] minor units.
  final int monthly;
  final int yearly;

  /// Some amounts were in another currency, converted at today's rates.
  final bool estimated;

  /// Currencies with no rate: those subscriptions are left out of the totals
  /// (never guessed).
  final List<String> missingRates;

  /// Still charged (trial included; not those cancelled to the end of the
  /// paid period).
  final int active;

  /// Charged within the next [soonDays] days.
  final int renewingSoon;

  /// Marked "to cancel" or with a cancellation asked, not confirmed yet.
  final int toCancel;

  /// Cancelled, confirmed or ended.
  final int ended;

  /// Monthly cost by card name (null = no card), in [base] minor units,
  /// largest first.
  final List<({String? card, int monthly, int count})> byCard;

  static const int soonDays = 7;

  /// [rule]'s amount as a monthly figure (same currency): weekly x 52 / 12,
  /// quarterly / 3, half-yearly / 6, yearly / 12.
  static int monthlyOf(RecurringRule rule) {
    final int a = rule.amount.minorUnits;
    return switch (rule.frequency) {
      RecurrenceFrequency.weekly => (a * 52 / 12).round(),
      RecurrenceFrequency.monthly => a,
      RecurrenceFrequency.quarterly => (a / 3).round(),
      RecurrenceFrequency.halfYearly => (a / 6).round(),
      RecurrenceFrequency.yearly => (a / 12).round(),
    };
  }

  static SubscriptionSummary of(
    Iterable<({Subscription sub, RecurringRule? rule})> items,
    DateTime now, {
    required String base,
    required Map<String, double> ratesVsUsd,
  }) {
    final DateTime today = RecurrenceEngine.dateOnly(now);
    final DateTime soon =
        DateTime(today.year, today.month, today.day + soonDays);
    int monthly = 0, active = 0, renewingSoon = 0, toCancel = 0, ended = 0;
    bool estimated = false;
    final Set<String> missing = <String>{};
    final Map<String?, ({int monthly, int count})> cards =
        <String?, ({int monthly, int count})>{};
    for (final ({Subscription sub, RecurringRule? rule}) i in items) {
      final Subscription s = i.sub;
      final RecurringRule? r = i.rule;
      if (s.isOver) {
        ended++;
        continue;
      }
      if (s.status == SubscriptionStatus.cancelWanted ||
          s.status == SubscriptionStatus.cancelRequested) {
        toCancel++;
      }
      if (SubscriptionCancel.stopsCharges(s.status) || r == null) continue;
      active++;
      if (!SubscriptionSchedule.nextCharge(r, now).isAfter(soon)) {
        renewingSoon++;
      }
      final Money perMonth = Money(monthlyOf(r), r.amount.currencyCode);
      final Money? inBase = WalletMath.convert(perMonth, base, ratesVsUsd);
      if (inBase == null) {
        missing.add(r.amount.currencyCode);
        continue;
      }
      if (r.amount.currencyCode != base) estimated = true;
      monthly += inBase.minorUnits;
      final ({int monthly, int count}) c =
          cards[s.cardName] ?? (monthly: 0, count: 0);
      cards[s.cardName] =
          (monthly: c.monthly + inBase.minorUnits, count: c.count + 1);
    }
    final List<({String? card, int monthly, int count})> byCard =
        <({String? card, int monthly, int count})>[
      for (final MapEntry<String?, ({int monthly, int count})> e
          in cards.entries)
        (card: e.key, monthly: e.value.monthly, count: e.value.count),
    ]..sort((a, b) => b.monthly.compareTo(a.monthly));
    return SubscriptionSummary(
      base: base,
      monthly: monthly,
      yearly: monthly * 12,
      estimated: estimated,
      missingRates: missing.toList()..sort(),
      active: active,
      renewingSoon: renewingSoon,
      toCancel: toCancel,
      ended: ended,
      byCard: byCard,
    );
  }
}
