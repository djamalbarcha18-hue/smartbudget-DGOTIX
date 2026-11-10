/// Carrying an invite code from the link to the new account.
///
/// Someone opens an invite link, reads the page, and only then signs up — and
/// confirming the mailbox sends them back through a fresh page load. The code
/// has to survive all of that, so it is kept on the device until an account
/// exists to attach it to, then redeemed once and forgotten.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/application/auth_controller.dart';

import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_link.dart';

class ReferralClaim {
  const ReferralClaim(this._service);

  final ReferralService _service;

  /// Where the pending code waits between opening the link and signing up.
  static const String prefKey = 'referral_pending_code';

  /// Notes the code in [url], if there is one. Does nothing else: the person
  /// has not signed up yet, and may never.
  Future<void> remember(Uri url) async {
    final String? code = ReferralLink.codeIn(url);
    if (code == null) return;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      // The first invite wins. Someone who opens a second link later is
      // already attributed, and the server would refuse it anyway.
      if ((p.getString(prefKey) ?? '').isEmpty) {
        await p.setString(prefKey, code);
      }
    } catch (_) {
      // No store (private browsing): the invite is simply not carried.
    }
  }

  /// Redeems a waiting code for the account that just signed in, and tells
  /// the server this account is up and running.
  ///
  /// Safe to call on every sign-in: the server keeps the first referral and
  /// ignores later ones, and [ReferralService.complete] only counts once.
  /// Returns true when a code was redeemed now.
  Future<bool> redeem() async {
    String? code;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      code = prefs.getString(prefKey);
    } catch (_) {
      return false;
    }

    bool claimed = false;
    if (ReferralLink.looksValid(code)) {
      claimed = await _service.claim(code!);
      // Clear it either way: a refused code (self-invite, an account that is
      // not new) will be refused every time, and retrying forever is noise.
      try {
        await prefs.remove(prefKey);
      } catch (_) {
        // Best effort.
      }
    }

    // Independent of the above: an account invited earlier, whose mailbox is
    // only confirmed now, becomes countable at this point.
    await _service.complete();
    return claimed;
  }
}

/// Whether an invite code is waiting on this device (someone opened an invite
/// link and has not signed up yet): the sign-up page then mentions the welcome
/// gift. Read once; false when there is no store.
final pendingInviteProvider = FutureProvider<bool>((Ref ref) async {
  try {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return ReferralLink.looksValid(p.getString(ReferralClaim.prefKey));
  } catch (_) {
    return false;
  }
});

final referralClaimProvider = Provider<ReferralClaim>(
    (Ref ref) => ReferralClaim(ref.watch(referralServiceProvider)));

/// Redeems a waiting invite whenever an account signs in, once per account.
///
/// Watched for the app's lifetime (see SmartBudgetApp) so the code noted when
/// the invite link was opened is redeemed as soon as there is an account to
/// attach it to — including the sign-in that follows confirming the mailbox,
/// which is the moment the invite actually becomes countable.
final referralRedeemProvider = Provider<void>((Ref ref) {
  final String? uid = ref.watch(currentAccountIdProvider);
  if (uid == null || uid.isEmpty || uid == 'guest') return;
  // Fire and forget: nothing on screen waits for an invite.
  ref.read(referralClaimProvider).redeem().ignore();
});
