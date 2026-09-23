import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/guide/domain/guide_content.dart';
import 'package:smartbudget/features/onboarding/application/onboarding_controller.dart';
import 'package:smartbudget/features/onboarding/domain/onboarding.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// User guide — "how do I use this?" in one place: a short getting-started
/// path, then one expandable card per feature with steps and a button that
/// opens that feature. Content comes from [GuideContent] (EN + AR).
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<String> start = GuideContent.gettingStarted(ar: ar);
    final List<GuideTopic> topics = GuideContent.topics(ar: ar);

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
                  Icon(Icons.explore_outlined, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.guideTitle, style: t.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(l.guideSubtitle, style: t.bodySmall),
              const SizedBox(height: DsSpacing.xl),

              // Getting started.
              GlassCard(
                accent: c.brand,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.rocket_launch_outlined,
                            size: 18, color: c.brand),
                        const SizedBox(width: DsSpacing.sm),
                        Text(l.guideGettingStarted,
                            style: t.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.md),
                    for (int i = 0; i < start.length; i++)
                      _NumberedStep(index: i + 1, text: start[i]),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.xl),

              Text(l.guideFeatures, style: t.titleMedium),
              const SizedBox(height: DsSpacing.md),
              for (final GuideTopic topic in topics) ...<Widget>[
                _TopicCard(topic: topic),
                const SizedBox(height: DsSpacing.sm),
              ],

              const SizedBox(height: DsSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.search_rounded,
                      size: 14, color: c.textFaint),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(l.guideSearchTip,
                        style: t.labelSmall?.copyWith(color: c.textFaint)),
                  ),
                ],
              ),
              const _ReopenWelcomeLink(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon for a topic, keyed by its route (keeps the domain free of Flutter).
IconData _iconFor(String route) => switch (route) {
      '/dashboard' => Icons.dashboard_outlined,
      '/transactions' => Icons.receipt_long_outlined,
      '/expenses' => Icons.document_scanner_outlined,
      '/budget' => Icons.calendar_month_outlined,
      '/goals' => Icons.flag_outlined,
      '/debts' => Icons.account_balance_outlined,
      '/portfolio' => Icons.account_balance_wallet_outlined,
      '/health' => Icons.monitor_heart_outlined,
      '/reports' => Icons.insights_outlined,
      '/zakat' => Icons.mosque_outlined,
      '/markets' => Icons.travel_explore_outlined,
      '/assistant' => Icons.auto_awesome_outlined,
      '/plans' => Icons.workspace_premium_outlined,
      '/settings' => Icons.settings_outlined,
      _ => Icons.help_outline_rounded,
    };

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});
  final GuideTopic topic;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    return GlassCard(
      child: Theme(
        // Drop the divider lines ExpansionTile draws when expanded.
        data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: DsSpacing.sm),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: c.brand,
          collapsedIconColor: c.textFaint,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.12),
              borderRadius: DsRadius.brSm,
            ),
            child: Icon(_iconFor(topic.route), size: 20, color: c.brand),
          ),
          title: Text(topic.title,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(topic.summary,
              style: t.bodySmall?.copyWith(color: c.textMuted)),
          children: <Widget>[
            const SizedBox(height: DsSpacing.xs),
            for (int i = 0; i < topic.steps.length; i++)
              _NumberedStep(index: i + 1, text: topic.steps[i]),
            const SizedBox(height: DsSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.go(topic.route),
                icon: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: c.brand),
                label: Text(l.guideOpen,
                    style: t.labelLarge?.copyWith(color: c.brand)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.14),
              borderRadius: DsRadius.brPill,
            ),
            child: Text('$index',
                style: t.labelSmall?.copyWith(
                    color: c.brand, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: t.bodySmall?.copyWith(height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brings the dashboard welcome checklist back after it was hidden.
class _ReopenWelcomeLink extends ConsumerWidget {
  const _ReopenWelcomeLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingFlags? flags = ref.watch(onboardingFlagsProvider);
    if (flags == null || !flags.dismissed) return const SizedBox.shrink();
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () {
            ref.read(onboardingFlagsProvider.notifier).reopen();
            context.go('/dashboard');
          },
          icon: Icon(Icons.checklist_rounded, size: 16, color: c.brand),
          label: Text(l.onbReopen,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: c.brand)),
        ),
      ),
    );
  }
}
