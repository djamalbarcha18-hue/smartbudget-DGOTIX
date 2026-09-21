import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/brand/branded_title.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/assistant_controller.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/assistant/presentation/insight_view.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "DGOTIX AI" — the top smart insights surfaced on the dashboard. Reuses the
/// on-device rule-based engine and the shared insight presentation; tapping
/// "view details" opens the full DGOTIX AI page. No fabricated analysis.
class DgotixInsightsSection extends ConsumerWidget {
  const DgotixInsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final List<Insight> insights = ref.watch(insightsProvider);
    final List<Insight> shown = insights.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_outlined, size: 20, color: c.brand),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: BrandedTitle(l.brandAi,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => context.go('/assistant'),
              child: Text(l.viewDetails),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.md),
        GlassCard(
          child: shown.isEmpty
              ? Row(
                  children: <Widget>[
                    Icon(Icons.insights_outlined, size: 18, color: c.textFaint),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(l.assistantEmpty,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: c.textMuted)),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < shown.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(height: DsSpacing.lg, color: c.border),
                      _InsightRow(insight: shown[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final InsightView v = describeInsight(context, insight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: v.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(v.icon, size: 17, color: v.color),
        ),
        const SizedBox(width: DsSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xxs),
            child: Text(v.message,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
