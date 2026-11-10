/// The rewards journey: every three friends who join through the link earn one
/// reward of the member's choice (three steps, 3 / 6 / 9). The ladder, the
/// progress to the next step, the pick, the share button and the link.
///
/// Deliberately quiet: it lives where someone goes looking for it and never
/// interrupts. The app asks for a share in one other place only — when a
/// limit is actually reached — which is the moment the offer is useful rather
/// than noise.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_section_header.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/domain/referral_link.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/referrals/domain/reward_journey.dart';
import 'package:smartbudget/features/share/presentation/share_app_sheet.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class InviteRewardsCard extends ConsumerStatefulWidget {
  const InviteRewardsCard({super.key});

  @override
  ConsumerState<InviteRewardsCard> createState() => _InviteRewardsCardState();
}

class _InviteRewardsCardState extends ConsumerState<InviteRewardsCard> {
  bool _busy = false;

  Future<void> _pick(ReferralReward r) async {
    if (_busy) return;
    setState(() => _busy = true);
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    final bool ok = await chooseReward(ref, r);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      await showRewardCelebration(nav.context, rewardName(l, r));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.journeyPickFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    final String? code = ref.watch(referralCodeProvider).valueOrNull;
    final RewardJourney journey = ref.watch(rewardJourneyProvider);

    return GlassCard(
      accent: c.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(
            title: l.journeyTitle,
            icon: Icons.card_giftcard_rounded,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(l.inviteBody, style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.lg),
          if (code == null)
            // Signed out: the link belongs to an account, so say so plainly
            // rather than showing a button that cannot work.
            Text(l.inviteNeedAccount,
                style: t.bodySmall?.copyWith(color: c.textMuted))
          else ...<Widget>[
            _Ladder(journey: journey),
            const SizedBox(height: DsSpacing.lg),
            if (journey.picksAvailable > 0) ...<Widget>[
              _PickPanel(journey: journey, busy: _busy, onPick: _pick),
              const SizedBox(height: DsSpacing.lg),
            ],
            if (journey.complete)
              Text(l.journeyAllDone,
                  style: t.bodyMedium?.copyWith(
                      color: c.income, fontWeight: FontWeight.w700))
            else
              _Progress(journey: journey),
            const SizedBox(height: DsSpacing.lg),
            DsButton(
              label: l.shareTabInvite,
              icon: Icons.ios_share_rounded,
              expand: true,
              onPressed: () => ShareAppSheet.show(context),
            ),
            const SizedBox(height: DsSpacing.md),
            _LinkRow(code: code),
          ],
        ],
      ),
    );
  }
}

/// The reward's name in the person's language.
String rewardName(AppLocalizations l, ReferralReward r) => switch (r) {
      ReferralReward.salarySplit => l.planFeatSalarySplit,
      ReferralReward.healthDetails => l.featHealthDetails,
      ReferralReward.higherLimits => l.rewardHigherLimits,
    };

IconData _rewardIcon(ReferralReward r) => switch (r) {
      ReferralReward.salarySplit => Icons.call_split_rounded,
      ReferralReward.healthDetails => Icons.monitor_heart_outlined,
      ReferralReward.higherLimits => Icons.trending_up_rounded,
    };

/// The three steps (3, 6, 9 friends): a picked one shows its reward, one that
/// is earned waits to be picked, the rest are ahead.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.journey});
  final RewardJourney journey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final List<JourneyStep> steps = journey.steps;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 21),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: steps[i].state == JourneyStepState.locked
                        ? c.border
                        : c.brand,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 84,
            child: Column(
              children: <Widget>[
                _StepDot(step: steps[i]),
                const SizedBox(height: DsSpacing.xs),
                Text(l.journeyStepFriends(steps[i].friends),
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(
                        color: steps[i].state == JourneyStepState.locked
                            ? c.textMuted
                            : c.textPrimary,
                        fontWeight: FontWeight.w700)),
                if (steps[i].reward case final ReferralReward r)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(rewardName(l, r),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(color: c.income)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatefulWidget {
  const _StepDot({required this.step});
  final JourneyStep step;

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_StepDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // A step waiting to be picked breathes gently; nothing moves when the
  // platform asks for less motion.
  void _sync() {
    final bool wait = widget.step.state == JourneyStepState.pickable;
    if (wait && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!wait && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final JourneyStep s = widget.step;
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final (Color fill, Color ring, Widget icon) = switch (s.state) {
      JourneyStepState.picked => (
          c.income.withValues(alpha: 0.16),
          c.income,
          Icon(_rewardIcon(s.reward!), size: 22, color: c.income),
        ),
      JourneyStepState.pickable => (
          c.brand.withValues(alpha: 0.18),
          c.brand,
          Icon(Icons.card_giftcard_rounded, size: 22, color: c.brand),
        ),
      JourneyStepState.locked => (
          Colors.transparent,
          c.border,
          Icon(Icons.lock_outline_rounded, size: 18, color: c.textFaint),
        ),
    };
    Widget dot = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
            color: ring,
            width: s.state == JourneyStepState.locked ? 1.5 : 2),
      ),
      child: Center(child: icon),
    );
    if (s.state == JourneyStepState.picked) {
      dot = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          dot,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: c.bgElevated),
              child: Icon(Icons.check_circle_rounded,
                  size: 16, color: c.income),
            ),
          ),
        ],
      );
    }
    if (s.state == JourneyStepState.pickable && !reduce) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) => Transform.scale(
          scale: 1 + 0.08 * Curves.easeInOut.transform(_pulse.value),
          child: child,
        ),
        child: dot,
      );
    }
    return dot;
  }
}

/// "Pick your reward": one tap on the reward wanted.
class _PickPanel extends StatelessWidget {
  const _PickPanel(
      {required this.journey, required this.busy, required this.onPick});
  final RewardJourney journey;
  final bool busy;
  final ValueChanged<ReferralReward> onPick;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        borderRadius: DsRadius.brMd,
        color: c.brand.withValues(alpha: 0.10),
        border: Border.all(color: c.brand.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.card_giftcard_rounded, color: c.brand, size: 20),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.journeyPickTitle,
                    style:
                        t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(l.journeyPickHint,
              style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.sm),
          for (final ReferralReward r in journey.remaining)
            Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xs),
              child: InkWell(
                borderRadius: DsRadius.brMd,
                onTap: busy ? null : () => onPick(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md, vertical: DsSpacing.sm + 2),
                  decoration: BoxDecoration(
                    borderRadius: DsRadius.brMd,
                    color: c.surfaceMuted,
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(_rewardIcon(r), size: 20, color: c.brand),
                      const SizedBox(width: DsSpacing.md),
                      Expanded(
                          child: Text(rewardName(l, r), style: t.bodyMedium)),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: c.textFaint),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A short, happy moment when a reward is picked: the gift pops in with the
/// name of what was unlocked.
Future<void> showRewardCelebration(BuildContext context, String name) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (BuildContext ctx, _, __) =>
        Center(child: _CelebrationCard(name: name)),
    transitionBuilder: (BuildContext ctx, Animation<double> a, _, Widget child) {
      final Animation<double> pop =
          CurvedAnimation(parent: a, curve: Curves.elasticOut);
      return FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: ScaleTransition(scale: pop, child: child),
      );
    },
  );
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Material(
      color: c.bgElevated,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(DsSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.brand.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: <Color>[c.brand, c.income],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: const Icon(Icons.celebration_rounded,
                  size: 38, color: Colors.white),
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(l.inviteUnlocked,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: DsSpacing.xs),
            Text(name,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.lg),
            DsButton(
              label: MaterialLocalizations.of(context).okButtonLabel,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The link, and the one button that matters on a phone: copy it.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String link = ReferralLink.invite(ShareQr.appUrl(), code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.inviteLink,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: DsSpacing.sm),
          decoration: BoxDecoration(
            color: c.brand.withValues(alpha: 0.08),
            borderRadius: DsRadius.brMd,
          ),
          // The link is Latin text; in an Arabic layout it must still read
          // left to right, or the code comes out backwards.
          child: Text(
            link,
            textDirection: TextDirection.ltr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        DsButton(
          label: l.shareCopyLink,
          icon: Icons.copy_rounded,
          variant: DsButtonVariant.secondary,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.inviteCopied)));
          },
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.journey});
  final RewardJourney journey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.inviteProgressLine(journey.activated, journey.nextMilestone),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DsSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: journey.fractionToNext),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double v, _) =>
                LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: c.brand.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(c.brand),
            ),
          ),
        ),
      ],
    );
  }
}
