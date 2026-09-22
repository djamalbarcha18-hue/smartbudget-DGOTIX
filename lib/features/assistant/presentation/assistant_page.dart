import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/ai_key_controller.dart';
import 'package:smartbudget/features/assistant/application/assistant_controller.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/assistant/presentation/ai_key_card.dart';
import 'package:smartbudget/features/assistant/presentation/ask_dgotix_card.dart';
import 'package:smartbudget/features/assistant/presentation/insight_view.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// AI Assistant — rule-based "smart insights" computed entirely on-device from
/// the user's own data. No financial rule is invented here: every line is
/// phrased by the presentation from an [Insight] the domain engine produced.
///
/// Users can optionally connect their OWN personal AI key (BYOK) via
/// [AiKeyCard]; that key is a personal secret kept only on the user's device and
/// is never shipped to or used by our servers.
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
              const AiKeyCard(),
              if (ref.watch(aiKeyConnectedProvider)) ...<Widget>[
                const SizedBox(height: DsSpacing.md),
                const AskDgotixCard(),
              ],
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
