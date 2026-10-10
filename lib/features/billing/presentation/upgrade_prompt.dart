import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
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
      Feature.seasons => l.featSeasons,
      Feature.recurringRules => l.featRecurring,
      Feature.healthDetails => l.featHealthDetails,
      Feature.prioritySupport => l.planFeatPriority,
      Feature.salarySplit => l.planFeatSalarySplit,
      Feature.smartAlerts => l.featSmartAlerts,
    };

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
    final GateDecision d = FeatureGate.evaluate(feature,
        plan: c.read(effectivePlanProvider), used: count(c));
    if (d.allowed) return true;
    UpgradeSheet.show(context, d);
    return false;
  }

  /// Whether the plan includes [feature]; shows the upgrade sheet if not.
  static bool allow(BuildContext context, Feature feature) =>
      allowAdd(context, feature, (_) => 0);
}

/// The sheet shown when a plan limit is reached or a feature is locked.
class UpgradeSheet extends StatelessWidget {
  const UpgradeSheet({super.key, required this.decision});

  final GateDecision decision;

  static Future<void> show(BuildContext context, GateDecision decision) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => UpgradeSheet(decision: decision),
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Plan tier = decision.suggestedTier ?? Plan.basic;
    final String name = featureTitle(l, decision.feature);
    final bool counted = decision.window == QuotaWindow.items;
    final String body = counted && decision.limit != null
        ? l.upgradeLimitBody(name, decision.limit!, planName(l, tier))
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
            DsButton(
              label: l.upgradeSeePlans,
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/plans');
              },
            ),
            const SizedBox(height: DsSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.upgradeNotNow),
            ),
          ],
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
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          DsButton(
            label: l.upgradeSeePlans,
            variant: DsButtonVariant.secondary,
            onPressed: () => context.go('/plans'),
          ),
        ],
      ),
    );
  }
}
