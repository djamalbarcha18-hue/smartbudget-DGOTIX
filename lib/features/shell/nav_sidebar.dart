import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/brand/dgotix_brand_lockup.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Professional desktop sidebar (also used inside the mobile drawer).
class NavSidebar extends StatelessWidget {
  const NavSidebar({
    super.key,
    required this.currentRoute,
    required this.onSelect,
    this.width = 264,
  });

  final String currentRoute;
  final ValueChanged<String> onSelect;
  final double width;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.bgElevated,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DsSpacing.lg,
              vertical: DsSpacing.xl,
            ),
            child: DgotixBrandLockup(
                logoHeight: 56, gap: DsSpacing.sm, showTagline: true),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.md,
              ),
              children: _buildGroupedItems(context, l),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: _UpgradeCard(l: l),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems(BuildContext context, AppLocalizations l) {
    final List<Widget> out = <Widget>[];
    NavGroup? lastGroup;
    for (final NavDestination d in AppNav.destinations) {
      if (d.group != lastGroup) {
        out.add(_GroupHeader(group: d.group, l: l));
        lastGroup = d.group;
      }
      out.add(
        _NavItem(
          destination: d,
          label: d.label(l),
          selected: currentRoute == d.route ||
              (currentRoute == '/' && d.section == AppSection.dashboard),
          onTap: () => onSelect(d.route),
        ),
      );
    }
    return out;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.l});
  final NavGroup group;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final String text = switch (group) {
      NavGroup.overview => l.navGroupOverview,
      NavGroup.money => l.navGroupMoney,
      NavGroup.planning => l.navGroupPlanning,
      NavGroup.intelligence => l.navGroupIntelligence,
      NavGroup.system => l.navGroupSystem,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.lg,
        DsSpacing.md,
        DsSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c.textFaint,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final Color fg = selected ? c.brand : c.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? c.brand.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: DsRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: DsRadius.brMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Icon(destination.icon, size: 20, color: fg),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected ? c.textPrimary : c.textMuted,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (destination.isNew)
                  DsBadge(
                    label: AppLocalizations.of(context).badgeNew,
                    tone: DsBadgeTone.income,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return GlassCard(
      accent: c.warning,
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.workspace_premium_outlined, size: 18, color: c.warning),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  l.upgradeTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(l.upgradeSubtitle, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.upgradeCta,
            expand: true,
            // Billing is a future phase (AppConfig-gated); no-op for now.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
