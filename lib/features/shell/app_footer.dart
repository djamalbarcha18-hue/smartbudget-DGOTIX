import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Compact, brand-consistent footer. RTL/LTR + dark/light aware. Kept low so it
/// never steals space from the dashboard.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextStyle? linkStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(color: c.textMuted);

    Widget link(String text, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: c.textMuted,
          ),
          child: Text(text, style: linkStyle),
        );

    final List<Widget> links = <Widget>[
      link(l.footerPrivacy, () => context.go('/legal/privacy')),
      link(l.footerTerms, () => context.go('/legal/terms')),
      link(l.footerHelp, () => context.go('/support')),
      link(l.footerContact, () => context.go('/support')),
    ];

    final Widget rights = Text(
      '${l.footerProductBy}   ·   ${l.footerRights(AppConfig.copyrightYear)}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: c.textFaint,
          ),
    );

    // Phones: one slim line that scrolls sideways, so the footer doesn't eat
    // the small screen.
    if (context.isMobile) {
      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
          child: Row(children: <Widget>[
            ...links,
            const SizedBox(width: DsSpacing.md),
            rights,
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.xl,
        vertical: DsSpacing.md,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: DsSpacing.sm,
        children: <Widget>[
          rights,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: links,
          ),
        ],
      ),
    );
  }
}
