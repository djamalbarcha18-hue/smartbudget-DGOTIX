import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/brand/dgotix_brand_lockup.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/shell/brand_controls.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Shared, branded layout for auth screens: a centered glass card over the
/// premium background, with the DGOTIX lockup and theme/language toggles.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: DsSpacing.md,
              right: DsSpacing.md,
              child: Row(
                children: <Widget>[LanguageToggleButton(), ThemeToggleButton()],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DsSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const DgotixBrandLockup(logoHeight: 56),
                      const SizedBox(height: DsSpacing.xs),
                      Text(l.authTagline, style: t.labelMedium),
                      const SizedBox(height: DsSpacing.x3l),
                      GlassCard(
                        padding: const EdgeInsets.all(DsSpacing.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(title, style: t.titleLarge),
                            const SizedBox(height: DsSpacing.xs),
                            Text(subtitle, style: t.bodySmall),
                            const SizedBox(height: DsSpacing.xl),
                            ...children,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
