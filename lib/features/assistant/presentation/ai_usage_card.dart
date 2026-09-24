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
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// DGOTIX AI usage as the user thinks about it: answers used out of the plan's
/// allowance and when it renews — never tokens, dollar costs or model names
/// (those are internal). When it runs out, the only action is Upgrade.
class AiUsageCard extends ConsumerWidget {
  const AiUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final GateDecision d = ref.watch(featureGateProvider(Feature.dgotixAi));
    final int? limit = d.limit;
    final int used =
        (limit != null && d.remaining != null) ? limit - d.remaining! : 0;
    final double ratio = d.usedFraction ?? 0;
    final Color bar =
        ratio >= 1 ? c.expense : (ratio >= 0.8 ? c.warning : c.brand);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.speed_rounded, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(l.usageTitle,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          if (limit == null)
            Text(l.usageEmpty, style: t.bodySmall)
          else ...<Widget>[
            Text(l.usageQuotaUsed(used, limit),
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: DsSpacing.sm),
            ClipRRect(
              borderRadius: DsRadius.brPill,
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: c.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(bar),
              ),
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
                d.window == QuotaWindow.lifetime
                    ? l.usageQuotaLifetime
                    : l.usageQuotaMonthly,
                style: t.labelSmall?.copyWith(color: c.textFaint)),
            if (!d.allowed) ...<Widget>[
              const SizedBox(height: DsSpacing.md),
              DsButton(
                label: l.upgradeCta,
                icon: Icons.workspace_premium_outlined,
                onPressed: () => context.go('/plans'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
