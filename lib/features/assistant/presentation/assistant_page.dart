import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/assistant/application/assistant_controller.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// AI Assistant — rule-based "smart insights" computed entirely on-device from
/// the user's own data. No financial rule is invented here: every line is
/// phrased by the presentation from an [Insight] the domain engine produced.
///
/// A conversational assistant (server-side model) is intentionally deferred to
/// the backend phase — no API secret ever ships in the client.
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
                  Text(l.pageAssistant,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(l.assistantSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
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
    final DsColors c = context.dsColors;
    final Color tone = _toneColor(insight.tone, c);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(_toneIcon(insight.tone), size: 20, color: tone),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: DsSpacing.xxs),
              child: Text(
                _message(context, insight),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _toneColor(InsightTone t, DsColors c) => switch (t) {
        InsightTone.positive => c.income,
        InsightTone.warning => c.warning,
        InsightTone.info => c.brand,
      };

  static IconData _toneIcon(InsightTone t) => switch (t) {
        InsightTone.positive => Icons.check_circle_outline_rounded,
        InsightTone.warning => Icons.warning_amber_rounded,
        InsightTone.info => Icons.lightbulb_outline_rounded,
      };

  /// Maps an [Insight] to its localized sentence. Money and percentages are
  /// formatted here (presentation), never in the domain engine.
  String _message(BuildContext context, Insight i) {
    final AppLocalizations l = AppLocalizations.of(context);
    String money(int? minor) =>
        MoneyFormatter.format(Money(minor ?? 0, i.currency ?? 'USD'));
    return switch (i.key) {
      InsightKey.netDeficit => l.insightNetDeficit(money(i.amountMinor)),
      InsightKey.netSurplus => l.insightNetSurplus(money(i.amountMinor)),
      InsightKey.savingsRate =>
        l.insightSavingsRate(MoneyFormatter.percent(i.rate ?? 0)),
      InsightKey.topExpenseCategory =>
        l.insightTopExpense(i.category ?? '', money(i.amountMinor)),
      InsightKey.healthExcellent => l.insightHealthExcellent,
      InsightKey.healthVeryGood => l.insightHealthVeryGood,
      InsightKey.healthGood => l.insightHealthGood,
      InsightKey.healthFair => l.insightHealthFair,
      InsightKey.healthNeedsWork => l.insightHealthNeedsWork,
      InsightKey.goalsAchieved => l.insightGoalsAchieved(i.count ?? 0),
      InsightKey.goalsUrgent => l.insightGoalsUrgent(i.count ?? 0),
      InsightKey.debtsOverdue => l.insightDebtsOverdue(i.count ?? 0),
      InsightKey.debtsOwedToMe => l.insightDebtsOwedToMe(money(i.amountMinor)),
      InsightKey.debtsOwedByMe => l.insightDebtsOwedByMe(money(i.amountMinor)),
      InsightKey.zakatDue => l.insightZakatDue(money(i.amountMinor)),
    };
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
