import 'package:smartbudget/features/subscriptions/domain/subscription.dart';

/// What the user says happened after going to cancel.
enum CancelOutcome {
  /// "I asked to cancel" (not confirmed by the provider).
  requested,

  /// Cancelled, still usable until a date.
  activeUntilEnd,

  /// "I didn't finish": still meant to be cancelled.
  notFinished,

  /// The provider confirmed it (an email, a message). Only the user says so.
  confirmed,

  /// It has ended.
  ended,

  /// Changed their mind: active again.
  reactivated,
}

/// Cancelling, honestly: the app opens the right page and records what the
/// user says happened. It never marks anything cancelled on its own (pure:
/// no Flutter, no IO).
abstract final class SubscriptionCancel {
  /// Every Google Play subscription of the user, each with Cancel. An app can
  /// only link to the page of its own product, so this is the list.
  static const String googlePlayUrl =
      'https://play.google.com/store/account/subscriptions';

  /// Apple's subscriptions page.
  static const String appleUrl = 'https://apps.apple.com/account/subscriptions';

  /// Where to cancel [s]: the store that bills it, else its management page
  /// (typed by the user or from the catalog). Null: no page known, the app
  /// shows the general steps.
  static Uri? destination(Subscription s) {
    switch (s.billedVia) {
      case BilledVia.googlePlay:
        return Uri.parse(googlePlayUrl);
      case BilledVia.appleStore:
        return Uri.parse(appleUrl);
      case BilledVia.direct:
      case BilledVia.carrier:
      case BilledVia.other:
        final String? u = s.manageUrl;
        return u != null && isSafeUrl(u) ? Uri.parse(u.trim()) : null;
    }
  }

  /// A web address the app may open: https, with a host.
  static bool isSafeUrl(String raw) {
    final Uri? u = Uri.tryParse(raw.trim());
    return u != null && u.scheme == 'https' && u.host.contains('.');
  }

  /// [raw] as a link to keep, or null when empty; "netflix.com/cancel"
  /// becomes https. Anything else unsafe is refused (null).
  static String? cleanUrl(String? raw) {
    final String t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    final String withScheme = t.contains('://') ? t : 'https://$t';
    return isSafeUrl(withScheme) ? withScheme : null;
  }

  /// Whether [status] means no more charges: reminders and the rule stop.
  static bool stopsCharges(SubscriptionStatus status) =>
      status == SubscriptionStatus.activeUntilEnd ||
      status == SubscriptionStatus.cancelConfirmed ||
      status == SubscriptionStatus.ended;

  /// [s] after [outcome], on [now]. [paidUntil] is the end of the paid
  /// period (required for [CancelOutcome.activeUntilEnd]).
  static Subscription apply(Subscription s, CancelOutcome outcome,
      DateTime now, {DateTime? paidUntil}) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    switch (outcome) {
      case CancelOutcome.requested:
        return s.copyWith(
          status: SubscriptionStatus.cancelRequested,
          cancelRequestedAt: s.cancelRequestedAt ?? now,
          updatedAt: now,
        );
      case CancelOutcome.activeUntilEnd:
        return s.copyWith(
          status: SubscriptionStatus.activeUntilEnd,
          cancelRequestedAt: s.cancelRequestedAt ?? now,
          paidUntil: paidUntil ?? today,
          updatedAt: now,
        );
      case CancelOutcome.notFinished:
        // A request already made stays made.
        return s.status == SubscriptionStatus.cancelRequested
            ? s
            : s.copyWith(
                status: SubscriptionStatus.cancelWanted, updatedAt: now);
      case CancelOutcome.confirmed:
        return s.copyWith(
          status: SubscriptionStatus.cancelConfirmed,
          cancelRequestedAt: s.cancelRequestedAt ?? now,
          endedAt: paidUntil ?? s.paidUntil ?? today,
          updatedAt: now,
        );
      case CancelOutcome.ended:
        return s.copyWith(
          status: SubscriptionStatus.ended,
          endedAt: paidUntil ?? s.paidUntil ?? today,
          updatedAt: now,
        );
      case CancelOutcome.reactivated:
        final DateTime? trial = s.trialEndsAt;
        return s.copyWith(
          status: trial != null && !trial.isBefore(today)
              ? SubscriptionStatus.trial
              : SubscriptionStatus.active,
          clearCancellation: true,
          clearKept: true,
          updatedAt: now,
        );
    }
  }
}
