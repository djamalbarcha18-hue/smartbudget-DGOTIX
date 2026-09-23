import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/plan_labels.dart';
import 'package:smartbudget/features/salary_split/presentation/salary_split_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Entry point on the Monthly Budget screen. On a paid plan it opens the
/// split; on FREE it explains the feature and points to the upgrade (never to
/// a workaround).
class SalarySplitCard extends ConsumerWidget {
  const SalarySplitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final GateDecision gate =
        ref.watch(featureGateProvider(Feature.salarySplit));
    final Plan tier = gate.suggestedTier ?? Plan.basic;

    return GlassCard(
      accent: c.brand,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.12),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(Icons.call_split_rounded, color: c.brand),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DsSpacing.sm,
                  children: <Widget>[
                    Text(l.splitTitle,
                        style: t.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (!gate.allowed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DsSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.brand.withValues(alpha: 0.14),
                          borderRadius: DsRadius.brPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.lock_outline_rounded,
                                size: 12, color: c.brand),
                            const SizedBox(width: 3),
                            Text(planName(l, tier),
                                style: t.labelSmall?.copyWith(
                                    color: c.brand,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l.splitHint,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                const SizedBox(height: DsSpacing.md),
                DsButton(
                  label: gate.allowed
                      ? l.splitSuggest
                      : l.splitUnlock(planName(l, tier)),
                  icon: gate.allowed
                      ? Icons.auto_awesome_outlined
                      : Icons.arrow_upward_rounded,
                  variant: gate.allowed
                      ? DsButtonVariant.primary
                      : DsButtonVariant.secondary,
                  onPressed: () => gate.allowed
                      ? SalarySplitSheet.show(context)
                      : context.go('/plans'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
