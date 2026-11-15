import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/components/ds_back_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The founder page: who is behind DGoTix, in a few lines.
///
/// The role as founder and the digital-product focus lead; the engineering
/// and production background is a small secondary section. Every line comes
/// from [AppConfig] (single source of truth). The professional lines are
/// written in English in every language, like a name; only the page title
/// and the contact labels follow the user's language.
///
/// Hidden until launched: the route and the link in Help & Support exist only
/// when `AppEnv.founderPage` is on.
class FounderPage extends StatelessWidget {
  const FounderPage({super.key});

  /// The founder's initials for the avatar: the first letters of the first
  /// two names (family name, then given name).
  static String initialsOf(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    const String email = AppConfig.founderEmail;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const DsBackButton(fallbackRoute: '/support'),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(l.founderTitle, style: t.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.xl),

              // Who: name, role as founder, and the professional focus.
              GlassCard(
                accent: c.brand,
                hoverable: false,
                padding: const EdgeInsets.all(DsSpacing.xxl),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.brand.withValues(alpha: 0.14),
                        border: Border.all(
                            color: c.brand.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        initialsOf(AppConfig.founderName),
                        style: t.titleLarge?.copyWith(
                            color: c.brand, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    Text(
                      AppConfig.founderName,
                      key: const ValueKey<String>('founder-name'),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: t.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: DsSpacing.xs),
                    Text(
                      AppConfig.founderRole,
                      key: const ValueKey<String>('founder-role'),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: t.titleSmall?.copyWith(color: c.brand),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    Divider(height: 1, color: c.border),
                    const SizedBox(height: DsSpacing.lg),
                    Text(
                      'Professional Focus',
                      textDirection: TextDirection.ltr,
                      style: t.labelSmall?.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: DsSpacing.xs),
                    Text(
                      AppConfig.founderFocus,
                      key: const ValueKey<String>('founder-focus'),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: t.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Secondary: the background, as two quiet tags, nothing more.
              GlassCard(
                hoverable: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Professional Background',
                      textDirection: TextDirection.ltr,
                      style: t.labelMedium?.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: DsSpacing.md),
                    Wrap(
                      spacing: DsSpacing.sm,
                      runSpacing: DsSpacing.sm,
                      children: <Widget>[
                        for (final String item in AppConfig.founderBackground)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: DsSpacing.md,
                                vertical: DsSpacing.xs + 2),
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: DsRadius.brPill,
                              border: Border.all(color: c.border),
                            ),
                            child: Text(
                              item,
                              textDirection: TextDirection.ltr,
                              style:
                                  t.bodySmall?.copyWith(color: c.textMuted),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Contact: the general inbox (not support).
              GlassCard(
                hoverable: false,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.mail_outline_rounded,
                        size: 18, color: c.textMuted),
                    const SizedBox(width: DsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.supportContact,
                              style: t.labelSmall
                                  ?.copyWith(color: c.textMuted)),
                          const SizedBox(height: 2),
                          Text(email,
                              key: const ValueKey<String>('founder-email'),
                              textDirection: TextDirection.ltr,
                              style: t.titleSmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l.supportWriteEmail,
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'mailto', path: email)),
                      icon:
                          Icon(Icons.send_outlined, size: 16, color: c.brand),
                    ),
                    IconButton(
                      tooltip: l.supportCopyEmail,
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: email));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.supportEmailCopied)),
                          );
                        }
                      },
                      icon:
                          Icon(Icons.copy_outlined, size: 16, color: c.brand),
                    ),
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
