import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/domain/reward_journey.dart';
import 'package:smartbudget/features/share/application/share_controller.dart';
import 'package:smartbudget/features/share/domain/share_highlight.dart';
import 'package:smartbudget/features/share/presentation/share_app_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Keeps the invite count fresh while the app is open and, when it rises,
/// shows a short happy note over the app: "A friend joined! 2 more to go", or
/// "Your reward is ready" when a pick is waiting. Tapping it opens Settings,
/// where the rewards journey is.
///
/// The count is read again every few minutes and when the app comes back to
/// the screen (one small call, counts only). The last count shown is kept per
/// account on the device, so a note appears once for each new friend and never
/// for friends already counted on another device.
class ReferralCelebration extends ConsumerStatefulWidget {
  const ReferralCelebration(
      {super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  /// How often the count is read again while the app stays open.
  static const Duration every = Duration(minutes: 5);

  @override
  ConsumerState<ReferralCelebration> createState() =>
      _ReferralCelebrationState();
}

class _ReferralCelebrationState extends ConsumerState<ReferralCelebration> {
  static const String _seenBase = 'sb_referral_seen';
  static const String _giftSeenBase = 'sb_welcome_gift_seen';
  static const String _goalsSeenBase = 'sb_moment_goals_seen';
  static const String _momentLastBase = 'sb_moment_last';
  static const String _ambassadorSeenBase = 'sb_ambassador_seen';

  /// At most one "share this" note this often.
  static const Duration momentGap = Duration(days: 7);

  Timer? _timer;
  Timer? _hide;
  AppLifecycleListener? _life;
  String? _uid;
  String? _note;
  bool _noteOpensShare = false;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _refresh);
    ref.listenManual<String?>(
      currentAccountIdProvider,
      (String? _, String? uid) => _setUp(uid),
      fireImmediately: true,
    );
    ref.listenManual<int>(
      shareHighlightProvider.select((ShareHighlight h) => h.goalsCompleted),
      (_, int n) => _onGoals(n),
    );
    ref.listenManual<bool>(
      rewardJourneyProvider.select((RewardJourney j) => j.isAmbassador),
      (_, bool yes) {
        if (yes) _onAmbassador();
      },
    );
    ref.listenManual<AsyncValue<DateTime?>>(
      welcomeGiftProvider,
      (_, AsyncValue<DateTime?> next) {
        final DateTime? at = next.valueOrNull;
        if (at != null) _onGift(at);
      },
    );
    ref.listenManual<AsyncValue<ReferralProgress>>(
      referralProgressProvider,
      (_, AsyncValue<ReferralProgress> next) {
        final ReferralProgress? p = next.valueOrNull;
        if (p != null) _onCount(p.activated);
      },
    );
  }

  void _setUp(String? uid) {
    _uid = uid;
    _timer?.cancel();
    _timer = null;
    if (uid == null) return;
    _timer = Timer.periodic(ReferralCelebration.every, (_) => _refresh());
  }

  void _refresh() {
    if (_uid == null || !mounted) return;
    ref.invalidate(referralProgressProvider);
    ref.invalidate(referralGrantsProvider);
  }

  /// The welcome gift of an invited person: said once, the first time it is
  /// seen on this device.
  Future<void> _onGift(DateTime at) async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = AccountKeys.of(_giftSeenBase, uid);
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      if (!mounted || _uid != uid) return;
      if (!ReferralRewards.welcomeGiftActive(at, AppClock.now())) return;
      _show(AppLocalizations.of(context)
          .inviteGiftReceived(ReferralRewards.welcomeGiftDays));
    } catch (_) {
      // A note is a nicety: never let it break anything.
    }
  }

  /// A good moment to share: a goal was just reached. Offered at most once a
  /// week, and never for goals already completed when this device first saw
  /// the count.
  Future<void> _onGoals(int completed) async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String seenKey = AccountKeys.of(_goalsSeenBase, uid);
      final String lastKey = AccountKeys.of(_momentLastBase, uid);
      final int? seen = prefs.getInt(seenKey);
      await prefs.setInt(seenKey, completed);
      if (seen == null || completed <= seen || !mounted || _uid != uid) return;
      final int now = AppClock.now().millisecondsSinceEpoch;
      final int? last = prefs.getInt(lastKey);
      if (last != null && now - last < momentGap.inMilliseconds) return;
      await prefs.setInt(lastKey, now);
      if (!mounted) return;
      _show(AppLocalizations.of(context).shareMomentGoal, share: true);
    } catch (_) {
      // A note is a nicety: never let it break anything.
    }
  }

  /// The ambassador title was just earned: said once.
  Future<void> _onAmbassador() async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = AccountKeys.of(_ambassadorSeenBase, uid);
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      if (!mounted || _uid != uid) return;
      _show(AppLocalizations.of(context).shareMomentAmbassador, share: true);
    } catch (_) {
      // A note is a nicety: never let it break anything.
    }
  }

  /// Opens the share sheet on the achievement card, from above the Navigator.
  void _openShare() {
    final BuildContext? nav =
        widget.router.routerDelegate.navigatorKey.currentContext;
    if (nav != null) ShareAppSheet.show(nav, tab: ShareTab.progress);
  }

  void _show(String note, {bool share = false}) {
    _noteOpensShare = share;
    setState(() => _note = note);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 9), () {
      if (mounted) setState(() => _note = null);
    });
  }

  Future<void> _onCount(int activated) async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = AccountKeys.of(_seenBase, uid);
      final int? seen = prefs.getInt(key);
      await prefs.setInt(key, activated);
      // The first time this device sees the count there is nothing to
      // celebrate: those friends were already counted.
      if (seen == null || activated <= seen || !mounted || _uid != uid) return;
      // The grants may not be in yet; the pick waiting is derived from the
      // count alone.
      await ref.read(referralGrantsProvider.future);
      if (!mounted) return;
      final RewardJourney j = ref.read(rewardJourneyProvider);
      final AppLocalizations l = AppLocalizations.of(context);
      _show(j.picksAvailable > 0
          ? l.journeyCelebrateReady
          : l.journeyCelebrateJoined(j.friendsToNext));
    } catch (_) {
      // A note is a nicety: never let it break anything.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide?.cancel();
    _life?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? note = _note;
    if (note == null) return widget.child;
    final DsColors c = context.dsColors;
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned(
          top: DsSpacing.md + MediaQuery.paddingOf(context).top,
          left: DsSpacing.md,
          right: DsSpacing.md,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Material(
                color: c.bgElevated,
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() => _note = null);
                    if (_noteOpensShare) {
                      _openShare();
                    } else {
                      widget.router.go('/settings');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        DsSpacing.md, DsSpacing.sm, DsSpacing.xs, DsSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: c.brand.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.celebration_rounded, color: c.brand),
                        const SizedBox(width: DsSpacing.md),
                        Expanded(
                          child: Text(note,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w700)),
                        ),
                        // No tooltip here: this sits above the app's
                        // Navigator, so there is no Overlay to show one in.
                        Semantics(
                          button: true,
                          label: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _note = null),
                            child: Padding(
                              padding: const EdgeInsets.all(DsSpacing.sm),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: c.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
