import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_popup.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/referrals/application/referrals_controller.dart';
import 'package:smartbudget/features/referrals/domain/referral_reward.dart';
import 'package:smartbudget/features/share/presentation/share_app_sheet.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/plan_labels.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What a gated feature is called in the upgrade prompts.
String featureTitle(AppLocalizations l, Feature f) => switch (f) {
      Feature.dgotixAi => l.featAi,
      Feature.cloudOcr => l.featCloudOcr,
      Feature.advancedReports => l.featAdvancedReports,
      Feature.cloudSyncFull => l.featSync,
      Feature.portfolioFull => l.featMarkets,
      Feature.parallelRates => l.featParallelRates,
      Feature.reportPdf => l.featReportPdf,
      Feature.reportTrends => l.featReportTrends,
      Feature.projects => l.featProjects,
      Feature.wallets => l.featWallets,
      Feature.multiCurrency => l.featMultiCurrency,
      Feature.categoryBudgets => l.featCategoryBudgets,
      Feature.goals => l.featGoals,
      Feature.debts => l.featDebts,
      Feature.darets => l.featDarets,
      Feature.daretMembers => l.featDaretMembers,
      Feature.seasons => l.featSeasons,
      Feature.recurringRules => l.featRecurring,
      Feature.healthDetails => l.featHealthDetails,
      Feature.prioritySupport => l.planFeatPriority,
      Feature.salarySplit => l.planFeatSalarySplit,
      Feature.smartAlerts => l.featSmartAlerts,
      Feature.tripPhotoCard => l.featTripPhotoCard,
      Feature.proThemes => l.featProThemes,
      Feature.categoryIcons => l.featCategoryIcons,
      Feature.metals => l.featMetals,
      Feature.metalsAdvanced => l.featMetalsAdvanced,
    };

/// One tap to invite: opens the app's own share sheet (branded card, progress
/// to the reward, a button per channel, the personal invite link and QR), so
/// whoever signs up through the link counts toward the reward. The sheet reads
/// the invite code itself and updates when it arrives.
Future<void> shareInviteLink(BuildContext context, WidgetRef ref,
    {bool closeSheet = false}) async {
  final NavigatorState navigator = Navigator.of(context);
  // Start loading the code now so it is usually ready by the time it shows.
  ref.read(referralCodeProvider);
  if (closeSheet) navigator.pop();
  if (!navigator.mounted) return;
  await ShareAppSheet.show(navigator.context);
}

/// Plan limits at the points where something new is added or opened. The
/// gate decides; this shows the upgrade sheet when it says no.
abstract final class PlanLimits {
  /// Whether one more [feature] item may be added, given how many exist
  /// ([count] reads it). Shows the upgrade sheet and returns false when the
  /// plan's limit is reached. Items already there are never taken away.
  static bool allowAdd(BuildContext context, Feature feature,
      int Function(ProviderContainer c) count) {
    final ProviderContainer c =
        ProviderScope.containerOf(context, listen: false);
    final Set<ReferralReward> rewards = c.read(activeRewardsProvider);
    final GateDecision d = FeatureGate.evaluate(feature,
        plan: c.read(effectivePlanProvider),
        used: count(c),
        // The same rewards featureGateProvider applies. Without this the
        // screen would show a raised limit and the add would still refuse.
        rewards: rewards);
    if (d.allowed) return true;
    // At a counted limit, someone who has not earned the invite reward yet is
    // also shown what three invited friends would raise it to.
    final int? invite = d.reason == GateReason.quotaReached &&
            !rewards.contains(ReferralReward.higherLimits)
        ? ReferralRewards.limitFor(
            const <ReferralReward>{ReferralReward.higherLimits}, feature)
        : null;
    // A locked feature that a reward opens outright (salary split, financial
    // health details) offers the invitation too, until it is earned.
    final ReferralReward? opener = ReferralRewards.opensWith(feature);
    final bool inviteUnlock = d.reason == GateReason.needsUpgrade &&
        opener != null &&
        !rewards.contains(opener);
    UpgradeSheet.show(context, d,
        inviteLimit: invite, inviteUnlock: inviteUnlock);
    return false;
  }

  /// Whether the plan includes [feature]; shows the upgrade sheet if not.
  static bool allow(BuildContext context, Feature feature) =>
      allowAdd(context, feature, (_) => 0);
}

/// The sheet shown when a plan limit is reached or a feature is locked.
class UpgradeSheet extends ConsumerWidget {
  const UpgradeSheet({
    super.key,
    required this.decision,
    this.inviteLimit,
    this.inviteUnlock = false,
  });

  final GateDecision decision;

  /// What inviting three friends would raise this limit to (−1: no limit), or
  /// null when that offer does not apply (a locked feature, or already earned).
  final int? inviteLimit;

  /// A locked feature that inviting three friends opens outright.
  final bool inviteUnlock;

  static Future<void> show(BuildContext context, GateDecision decision,
          {int? inviteLimit, bool inviteUnlock = false}) =>
      showModalBottomSheet<void>(
        context: context,
        // The default caps a sheet at 9/16 of the screen, which cuts the
        // buttons off on a short phone once the invitation is shown.
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UpgradeSheet(
            decision: decision,
            inviteLimit: inviteLimit,
            inviteUnlock: inviteUnlock),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Plan tier = decision.suggestedTier ?? Plan.pro;
    final String name = featureTitle(l, decision.feature);
    final bool counted = decision.window == QuotaWindow.items;
    final String body = counted && decision.limit != null
        ? (AppEnv.storeFreeMode
            ? l.storeLimitBody(name, decision.limit!)
            : l.upgradeLimitBody(name, decision.limit!, planName(l, tier)))
        : l.upgradeLockedBody(name, planName(l, tier));

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        // Scrolls when the screen is too short for everything at once.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.12),
                  borderRadius: DsRadius.brMd,
                ),
                child: Icon(Icons.lock_outline_rounded, color: c.brand),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            Text(
              counted
                  ? l.upgradeLimitTitle
                  : l.upgradeLockedTitle(planName(l, tier)),
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(body,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.xl),
            // The store app does not sell: no button to plans.
            if (!AppEnv.storeFreeMode)
            DsButton(
              label: l.upgradeSeePlans,
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                final NavigatorState nav = Navigator.of(context);
                nav.pop();
                UpgradePopup.show(nav.context);
              },
            ),
            if (inviteLimit != null || inviteUnlock) ...<Widget>[
              const SizedBox(height: DsSpacing.lg),
              Divider(color: c.border, height: 1),
              const SizedBox(height: DsSpacing.md),
              Text(
                  inviteUnlock
                      ? l.upgradeInviteBodyUnlock(name)
                      : inviteLimit! < 0
                          ? l.upgradeInviteBodyUnlimited(name)
                          : l.upgradeInviteBody(name, inviteLimit!),
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textMuted)),
              const SizedBox(height: DsSpacing.sm),
              DsButton(
                label: l.upgradeInviteCta,
                icon: Icons.card_giftcard_rounded,
                variant: DsButtonVariant.secondary,
                onPressed: () =>
                    shareInviteLink(context, ref, closeSheet: true),
              ),
            ],
            const SizedBox(height: DsSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.upgradeNotNow),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// A card standing in for a locked section of a page.
class LockedFeatureCard extends ConsumerWidget {
  const LockedFeatureCard({super.key, required this.feature});

  final Feature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Plan tier = FeatureCatalog.minTierFor(feature);
    // A section that inviting three friends opens outright says so, until
    // the reward is earned.
    final ReferralReward? opener = ReferralRewards.opensWith(feature);
    final bool invite =
        opener != null && !ref.watch(activeRewardsProvider).contains(opener);
    return GlassCard(
      accent: c.brand,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.12),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(Icons.lock_outline_rounded, color: c.brand),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(featureTitle(l, feature),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    l.upgradeLockedBody(
                        featureTitle(l, feature), planName(l, tier)),
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                if (invite) ...<Widget>[
                  const SizedBox(height: DsSpacing.xs),
                  Text(l.upgradeInviteBodyUnlock(featureTitle(l, feature)),
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => shareInviteLink(context, ref),
                      icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                      label: Text(l.upgradeInviteCta),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          DsButton(
            label: l.upgradeSeePlans,
            variant: DsButtonVariant.secondary,
            onPressed: () => UpgradePopup.show(context),
          ),
        ],
      ),
    );
  }
}
