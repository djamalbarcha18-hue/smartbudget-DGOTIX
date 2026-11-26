import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';

/// A digital service (Netflix, Spotify, ChatGPT…) or a phone / internet plan.
enum SubscriptionKind { digital, mobile }

/// What a phone or internet plan covers.
enum MobilePlanType { internet, calls, sms, mixed, topup }

/// Who charges it: where it is managed and cancelled.
enum BilledVia { direct, googlePlay, appleStore, carrier, other }

/// Where the subscription stands. Only the user sets [cancelConfirmed]: the
/// app never claims a cancellation the provider hasn't confirmed.
enum SubscriptionStatus {
  /// A free trial that turns into a paid plan on [Subscription.trialEndsAt].
  trial,
  active,

  /// The user means to cancel it but hasn't yet.
  cancelWanted,

  /// The user asked the provider to cancel; not confirmed.
  cancelRequested,

  /// Cancelled, still usable until [Subscription.paidUntil].
  activeUntilEnd,

  /// The provider confirmed the cancellation (the user says so).
  cancelConfirmed,
  ended,
}

/// A subscription the user wants to be reminded of before it is charged.
///
/// It only describes the service and how to manage it. The amount, currency,
/// cycle, wallet and the date of the next charge live in its
/// [RecurringRule] ([ruleId]), so the expense engine, reports and exports
/// keep working unchanged and nothing is counted twice.
///
/// Kept in a collection of its own (not in the rule) so an older app version
/// that rewrites the rule can't drop these fields.
@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.ruleId,
    required this.kind,
    required this.provider,
    this.catalogId,
    this.planName,
    this.mobileType,
    this.country,
    this.autoRenew = true,
    this.trialEndsAt,
    this.billedVia = BilledVia.direct,
    this.manageUrl,
    this.notes,
    this.remindersOn = true,
    this.reminderDays = const <int>[],
    this.reminderMinutes,
    this.keptUntil,
    this.status = SubscriptionStatus.active,
    this.cancelRequestedAt,
    this.paidUntil,
    this.endedAt,
    this.payments = const <String, String>{},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Ids of subscriptions and of their rules start with this, so the free
  /// sync can carry a subscription's rule without every other recurring rule.
  static const String idPrefix = 'sub-';

  static bool isSubscriptionRuleId(String id) => id.startsWith(idPrefix);

  final String id;

  /// The [RecurringRule] that holds the money and the schedule.
  final String ruleId;
  final SubscriptionKind kind;

  /// "Netflix", "Djezzy", or a name the user typed.
  final String provider;

  /// Its key in the built-in catalog, when picked from it.
  final String? catalogId;
  final String? planName;

  /// For [SubscriptionKind.mobile] only.
  final MobilePlanType? mobileType;

  /// ISO country code ("DZ"), to list the right carriers first.
  final String? country;

  /// Charged on its own at each renewal (a prepaid plan the user renews by
  /// hand is not).
  final bool autoRenew;

  /// End of a free trial: the first paid charge. Nothing is spent before it.
  final DateTime? trialEndsAt;
  final BilledVia billedVia;

  /// The provider's page to manage or cancel it.
  final String? manageUrl;
  final String? notes;

  final bool remindersOn;

  /// Days before the charge to remind on (0 = the day itself). Empty means
  /// the defaults for the cycle ([SubscriptionReminders.defaultsFor]).
  final List<int> reminderDays;

  /// Time of day of the reminders, in minutes after midnight; null = the
  /// app-wide setting.
  final int? reminderMinutes;

  /// "Keep it": no more reminders up to and including this charge date; they
  /// come back for the next cycle.
  final DateTime? keptUntil;
  final SubscriptionStatus status;
  final DateTime? cancelRequestedAt;

  /// End of the period already paid for.
  final DateTime? paidUntil;
  final DateTime? endedAt;

  /// Charge date ("2026-12-15") -> id of the transaction recorded for it
  /// (posted by the rule or an expense the user linked), so a charge is
  /// never recorded twice. Kept here, not on the transaction, so an older
  /// app version editing the transaction can't lose the link.
  final Map<String, String> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTrial =>
      status == SubscriptionStatus.trial && trialEndsAt != null;

  /// No longer charged: reminders and posting stop.
  bool get isOver =>
      status == SubscriptionStatus.ended ||
      status == SubscriptionStatus.cancelConfirmed;

  Subscription copyWith({
    String? provider,
    String? catalogId,
    String? planName,
    MobilePlanType? mobileType,
    String? country,
    bool? autoRenew,
    DateTime? trialEndsAt,
    bool clearTrial = false,
    BilledVia? billedVia,
    String? manageUrl,
    String? notes,
    bool? remindersOn,
    List<int>? reminderDays,
    int? reminderMinutes,
    bool clearReminderMinutes = false,
    DateTime? keptUntil,
    bool clearKept = false,
    SubscriptionStatus? status,
    DateTime? cancelRequestedAt,
    DateTime? paidUntil,
    DateTime? endedAt,
    Map<String, String>? payments,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id,
      ruleId: ruleId,
      kind: kind,
      provider: provider ?? this.provider,
      catalogId: catalogId ?? this.catalogId,
      planName: planName ?? this.planName,
      mobileType: mobileType ?? this.mobileType,
      country: country ?? this.country,
      autoRenew: autoRenew ?? this.autoRenew,
      trialEndsAt: clearTrial ? null : (trialEndsAt ?? this.trialEndsAt),
      billedVia: billedVia ?? this.billedVia,
      manageUrl: manageUrl ?? this.manageUrl,
      notes: notes ?? this.notes,
      remindersOn: remindersOn ?? this.remindersOn,
      reminderDays: reminderDays ?? this.reminderDays,
      reminderMinutes: clearReminderMinutes
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
      keptUntil: clearKept ? null : (keptUntil ?? this.keptUntil),
      status: status ?? this.status,
      cancelRequestedAt: cancelRequestedAt ?? this.cancelRequestedAt,
      paidUntil: paidUntil ?? this.paidUntil,
      endedAt: endedAt ?? this.endedAt,
      payments: payments ?? this.payments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? AppClock.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ruleId': ruleId,
        'kind': kind.name,
        'provider': provider,
        if (catalogId != null) 'catalogId': catalogId,
        if (planName != null) 'planName': planName,
        if (mobileType != null) 'mobileType': mobileType!.name,
        if (country != null) 'country': country,
        'autoRenew': autoRenew,
        if (trialEndsAt != null) 'trialEndsAt': _ymd(trialEndsAt!),
        'billedVia': billedVia.name,
        if (manageUrl != null) 'manageUrl': manageUrl,
        if (notes != null) 'notes': notes,
        'remindersOn': remindersOn,
        if (reminderDays.isNotEmpty) 'reminderDays': reminderDays,
        if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
        if (keptUntil != null) 'keptUntil': _ymd(keptUntil!),
        'status': status.name,
        if (cancelRequestedAt != null)
          'cancelRequestedAt': cancelRequestedAt!.toIso8601String(),
        if (paidUntil != null) 'paidUntil': _ymd(paidUntil!),
        if (endedAt != null) 'endedAt': _ymd(endedAt!),
        if (payments.isNotEmpty) 'payments': payments,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> j) {
    final DateTime created =
        DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
            AppClock.now();
    final String id = (j['id'] as String?) ?? '';
    return Subscription(
      id: id,
      ruleId: (j['ruleId'] as String?) ?? id,
      kind: _enum(SubscriptionKind.values, j['kind'], SubscriptionKind.digital),
      provider: (j['provider'] as String?) ?? '',
      catalogId: j['catalogId'] as String?,
      planName: j['planName'] as String?,
      mobileType: j['mobileType'] == null
          ? null
          : _enum(MobilePlanType.values, j['mobileType'], MobilePlanType.mixed),
      country: j['country'] as String?,
      autoRenew: (j['autoRenew'] as bool?) ?? true,
      trialEndsAt: _day(j['trialEndsAt']),
      billedVia: _enum(BilledVia.values, j['billedVia'], BilledVia.other),
      manageUrl: j['manageUrl'] as String?,
      notes: j['notes'] as String?,
      remindersOn: (j['remindersOn'] as bool?) ?? true,
      reminderDays: _days(j['reminderDays']),
      reminderMinutes: (j['reminderMinutes'] as num?)?.toInt(),
      keptUntil: _day(j['keptUntil']),
      // A status from a newer version reads as active: reminders keep
      // coming, the safe side for a charge the user may not want.
      status: _enum(
          SubscriptionStatus.values, j['status'], SubscriptionStatus.active),
      cancelRequestedAt:
          DateTime.tryParse((j['cancelRequestedAt'] as String?) ?? ''),
      paidUntil: _day(j['paidUntil']),
      endedAt: _day(j['endedAt']),
      payments: _payments(j['payments']),
      createdAt: created,
      updatedAt:
          DateTime.tryParse((j['updatedAt'] as String?) ?? '') ?? created,
    );
  }

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final T v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _day(Object? v) {
    if (v is! String) return null;
    final DateTime? d = DateTime.tryParse(v);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static List<int> _days(Object? v) {
    if (v is! List) return const <int>[];
    final Set<int> out = <int>{
      for (final Object? e in v)
        if (e is num && e >= 0 && e <= 30) e.toInt(),
    };
    return out.toList()..sort((int a, int b) => b.compareTo(a));
  }

  static Map<String, String> _payments(Object? v) {
    if (v is! Map) return const <String, String>{};
    return <String, String>{
      for (final MapEntry<Object?, Object?> e in v.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }
}

/// Which reminders a cycle offers (owner's decision, 2026-11-26): the earlier
/// the bigger the charge, since some services must be cancelled a full day
/// before they charge.
abstract final class SubscriptionReminders {
  /// Days before the end of a free trial.
  static const List<int> trialDays = <int>[2, 1];

  static List<int> choicesFor(RecurrenceFrequency f) => switch (f) {
        RecurrenceFrequency.weekly => const <int>[1, 0],
        RecurrenceFrequency.monthly ||
        RecurrenceFrequency.quarterly ||
        RecurrenceFrequency.halfYearly =>
          const <int>[3, 1, 0],
        RecurrenceFrequency.yearly => const <int>[7, 3, 1, 0],
      };

  static List<int> defaultsFor(RecurrenceFrequency f) => switch (f) {
        RecurrenceFrequency.weekly => const <int>[1],
        RecurrenceFrequency.monthly ||
        RecurrenceFrequency.quarterly ||
        RecurrenceFrequency.halfYearly =>
          const <int>[3, 1],
        RecurrenceFrequency.yearly => const <int>[7, 1],
      };

  /// The days [s] reminds on for a rule repeating every [f]: its own choice
  /// (limited to what the cycle offers), else the defaults.
  static List<int> daysFor(Subscription s, RecurrenceFrequency f) {
    final List<int> allowed = choicesFor(f);
    final List<int> own =
        s.reminderDays.where(allowed.contains).toList(growable: false);
    return own.isEmpty ? defaultsFor(f) : own;
  }
}
