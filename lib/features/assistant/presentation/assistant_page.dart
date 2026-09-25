import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/ai_backend.dart';
import 'package:smartbudget/features/assistant/application/assistant_controller.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/assistant/presentation/ai_usage_card.dart';
import 'package:smartbudget/features/assistant/presentation/ask_dgotix_card.dart';
import 'package:smartbudget/features/assistant/presentation/insight_view.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// AI Assistant — rule-based "smart insights" computed entirely on-device from
/// the user's own data. No financial rule is invented here: every line is
/// phrased by the presentation from an [Insight] the domain engine produced.
///
/// The conversational assistant is provided by DGOTIX itself (server gateway,
/// plan quotas); users never bring their own AI key.
class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Insight> insights = ref.watch(insightsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome_outlined,
                      color: context.dsColors.brand),
                  const SizedBox(width: DsSpacing.sm),
                  BrandedTitle(l.brandAi,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(l.assistantSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: DsSpacing.xl),
              // DGOTIX AI answers through our servers within the plan quota;
              // until that service is live, a clear "coming soon" card.
              if (ref.watch(assistantReadyProvider)) ...<Widget>[
                const AskDgotixCard(),
                const SizedBox(height: DsSpacing.md),
                const AiUsageCard(),
              ] else
                const _AssistantLockedCard(),
              const SizedBox(height: DsSpacing.xl),
              if (insights.isEmpty)
                _EmptyInsights(message: l.assistantEmpty)
              else ...<Widget>[
                Text(l.assistantInsightsTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DsSpacing.md),
                for (final Insight insight in insights) ...<Widget>[
                  _InsightCard(insight: insight),
                  const SizedBox(height: DsSpacing.md),
                ],
              ],
              const SizedBox(height: DsSpacing.sm),
              _DisclaimerNote(message: l.assistantDisclaimer),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final InsightView v = describeInsight(context, insight);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.14),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(v.icon, size: 20, color: v.color),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xxs),
              child: Text(
                v.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        children: <Widget>[
          Icon(Icons.insights_outlined, size: 32, color: c.textFaint),
          const SizedBox(height: DsSpacing.sm),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.shield_outlined, size: 14, color: c.textFaint),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: c.textFaint)),
        ),
      ],
    );
  }
}

/// Shown while the chat service isn't available yet: it is coming to every
/// plan, with answers included according to the subscription.
class _AssistantLockedCard extends StatelessWidget {
  const _AssistantLockedCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return GlassCard(
      accent: c.brand,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.12),
              borderRadius: DsRadius.brMd,
            ),
            child: Icon(Icons.forum_outlined, color: c.brand),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.aiLockedTitle,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: DsSpacing.xs),
                Text(l.aiLockedBody,
                    style: t.bodySmall?.copyWith(color: c.textMuted)),
                if (!AppEnv.betaAllAccess) ...<Widget>[
                  const SizedBox(height: DsSpacing.md),
                  DsButton(
                    label: l.aiLockedCta,
                    icon: Icons.workspace_premium_outlined,
                    variant: DsButtonVariant.secondary,
                    onPressed: () => context.go('/plans'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
