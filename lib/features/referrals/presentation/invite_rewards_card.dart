/// "Invite friends & unlock rewards" — the invite link, the progress to three,
/// and what those three open.
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
import 'package:smartbudget/features/referrals/data/referral_service.dart';
import 'package:smartbudget/features/referrals/domain/referral_link.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class InviteRewardsCard extends ConsumerWidget {
  const InviteRewardsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    final String? code = ref.watch(referralCodeProvider).valueOrNull;
    final ReferralProgress progress =
        ref.watch(referralProgressProvider).valueOrNull ??
            ReferralProgress.none;
    final Set<ReferralReward> earned = ref.watch(activeRewardsProvider);

    return GlassCard(
      accent: c.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DsSectionHeader(
            title: l.inviteTitle,
            icon: Icons.card_giftcard_rounded,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(l.inviteBody, style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.lg),

          // Signed out: the link belongs to an account, so say so plainly
          // rather than showing a button that cannot work.
          if (code == null)
            Text(l.inviteNeedAccount,
                style: t.bodySmall?.copyWith(color: c.textMuted))
          else
            _LinkRow(code: code),

          const SizedBox(height: DsSpacing.lg),
          _Progress(progress: progress),
          const SizedBox(height: DsSpacing.lg),
          Text(l.inviteRewards,
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DsSpacing.sm),
          for (final ReferralReward r in ReferralReward.values)
            _RewardLine(reward: r, earned: earned.contains(r)),
        ],
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
  const _Progress({required this.progress});
  final ReferralProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.inviteProgressLine(progress.activated, ReferralRewards.needed),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DsSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 8,
            backgroundColor: c.brand.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
                progress.earned ? c.income : c.brand),
          ),
        ),
      ],
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.reward, required this.earned});
  final ReferralReward reward;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final String name = switch (reward) {
      ReferralReward.salarySplit => l.planFeatSalarySplit,
      ReferralReward.healthDetails => l.featHealthDetails,
      ReferralReward.higherLimits => l.rewardHigherLimits,
    };
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            earned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: earned ? c.income : c.textMuted,
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: earned ? c.textPrimary : c.textMuted,
                    fontWeight: earned ? FontWeight.w700 : null,
                  ),
            ),
          ),
          if (earned)
            Text(l.inviteUnlocked,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: c.income, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
