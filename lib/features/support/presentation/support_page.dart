import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Help & Support — contact channel, legal resources, and an FAQ placeholder.
///
/// No financial logic. The support email/links come from [AppConfig] (single
/// source of truth). A full help center (guides, ticketing) plugs in later
/// without touching this screen's structure.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l.pageSupport,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: DsSpacing.xl),

              // Contact.
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.support_agent_outlined,
                            size: 18, color: c.brand),
                        const SizedBox(width: DsSpacing.sm),
                        Text(l.supportContact,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.xs),
                    Text(l.supportContactHint,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: DsSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(DsSpacing.md),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: DsRadius.brMd,
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.mail_outline_rounded,
                              size: 18, color: c.textMuted),
                          const SizedBox(width: DsSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(l.supportEmailLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: c.textMuted)),
                                const SizedBox(height: 2),
                                Text(AppConfig.supportEmail,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.supportCopyEmail,
                            onPressed: () async {
                              await Clipboard.setData(const ClipboardData(
                                  text: AppConfig.supportEmail));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l.supportEmailCopied)),
                                );
                              }
                            },
                            icon: Icon(Icons.copy_outlined,
                                size: 16, color: c.brand),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Resources / legal.
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.menu_book_outlined,
                            size: 18, color: c.brand),
                        const SizedBox(width: DsSpacing.sm),
                        Text(l.supportResources,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    _ResourceRow(
                        icon: Icons.help_center_outlined,
                        label: l.footerHelp),
                    _ResourceRow(
                        icon: Icons.privacy_tip_outlined,
                        label: l.footerPrivacy),
                    _ResourceRow(
                        icon: Icons.description_outlined,
                        label: l.footerTerms),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // FAQ placeholder (honest "coming soon" — no fake content).
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.quiz_outlined, size: 18, color: c.brand),
                        const SizedBox(width: DsSpacing.sm),
                        Text(l.supportFaq,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    Text(l.supportFaqSoon,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return InkWell(
      borderRadius: DsRadius.brMd,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.comingSoon)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: c.textMuted),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
