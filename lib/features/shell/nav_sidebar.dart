import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/components/glass_panel.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/presentation/plan_brand_lockup.dart';
import 'package:smartbudget/features/share/presentation/share_app_sheet.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/features/shell/nav_seen.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Professional desktop sidebar (also used inside the mobile drawer).
class NavSidebar extends StatelessWidget {
  const NavSidebar({
    super.key,
    required this.currentRoute,
    required this.onSelect,
    this.width = 264,
    this.floating = false,
  });

  final String currentRoute;
  final ValueChanged<String> onSelect;
  final double width;

  /// Desktop: a floating, rounded glass panel over the backdrop. Inside the
  /// mobile drawer it stays a plain full-height surface.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);

    final Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // A smaller lockup leaves the room to the menu.
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DsSpacing.lg,
              vertical: DsSpacing.lg,
            ),
            child: PlanBrandLockup(logoHeight: 40),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.md,
              ),
              children: _buildMenu(context, l),
            ),
          ),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DsSpacing.md, DsSpacing.xs, DsSpacing.md, 0),
            child: Row(
              children: <Widget>[
                for (final AppSection s in AppMenu.footer)
                  if (AppMenu.of(s) case final NavDestination d)
                    Expanded(
                      // "Help" is short; Settings gets the room ("Einstellungen").
                      flex: s == AppSection.helpSupport ? 2 : 3,
                      child: _NavItem(
                        destination: d,
                        // Short, side by side ("Help", not "Help & support").
                        label: s == AppSection.helpSupport
                            ? l.navHelpShort
                            : d.label(l),
                        selected: AppMenu.selectedFor(currentRoute) == s,
                        compact: true,
                        onTap: () => onSelect(d.route),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: _UpgradeCard(l: l),
          ),
        ],
    );
    if (floating) {
      return SizedBox(width: width, child: GlassPanel(child: body));
    }
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.bgElevated,
        border: BorderDirectional(end: BorderSide(color: c.border)),
      ),
      // In the drawer the surface runs under the status bar; the items don't.
      child: SafeArea(child: body),
    );
  }

  List<Widget> _buildMenu(BuildContext context, AppLocalizations l) {
    final AppSection? selected = AppMenu.selectedFor(currentRoute);
    Widget item(NavDestination d) => _NavItem(
          destination: d,
          label: d.label(l),
          selected: selected == d.section,
          onTap: () => onSelect(d.route),
        );
    return <Widget>[
      for (final AppSection s in AppMenu.main)
        if (AppMenu.of(s) case final NavDestination d) item(d),
      const SizedBox(height: DsSpacing.sm),
      for (final MapEntry<NavFold, List<AppSection>> f
          in AppMenu.folds.entries)
        if (<NavDestination>[
          for (final AppSection s in f.value)
            if (AppMenu.of(s) case final NavDestination d) d,
        ]
            case final List<NavDestination> items when items.isNotEmpty)
          _Fold(
            fold: f.key,
            items: items,
            // The page shown keeps its part of the menu open.
            open: AppMenu.foldOf(selected) == f.key,
            children: <Widget>[for (final NavDestination d in items) item(d)],
          ),
    ];
  }
}

/// A folded part of the menu: its name, what is inside in a line, and the
/// items once opened (smoothly).
class _Fold extends ConsumerStatefulWidget {
  const _Fold({
    required this.fold,
    required this.items,
    required this.open,
    required this.children,
  });
  final NavFold fold;
  final List<NavDestination> items;
  final bool open;
  final List<Widget> children;

  @override
  ConsumerState<_Fold> createState() => _FoldState();
}

class _FoldState extends ConsumerState<_Fold> {
  late bool _open = widget.open;

  @override
  void didUpdateWidget(_Fold old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) _open = true;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final (IconData icon, String title) = switch (widget.fold) {
      NavFold.tools => (Icons.tune_rounded, l.navFoldTools),
      NavFold.occasions => (Icons.celebration_outlined, l.navFoldOccasions),
      NavFold.markets => (Icons.currency_exchange_outlined, l.navGroupMarkets),
    };
    final Set<String> seen = ref.watch(navSeenProvider);
    final bool hasNew = widget.items
        .any((NavDestination d) => d.isNew && !seen.contains(d.route));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          borderRadius: DsRadius.brMd,
          child: InkWell(
            borderRadius: DsRadius.brMd,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.md, vertical: DsSpacing.sm + 2),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: c.textMuted),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(title,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyMedium?.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (hasNew && !_open) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    color: c.income, shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                        // What is inside, so nothing feels hidden.
                        if (!_open)
                          Text(
                            widget.items
                                .map((NavDestination d) => d.label(l))
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelSmall?.copyWith(color: c.textFaint),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        size: 20, color: c.textFaint),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: _open
              ? Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: DsSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final NavDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Settings and help at the bottom: smaller, side by side.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final DsGlass g = context.dsGlass;
    // Icons carry the logo blue, except the income / expense arrows which use
    // their universal colors; inactive icons are a touch softer.
    final Color base = switch (destination.section) {
      AppSection.income => c.income,
      AppSection.expenses => c.expense,
      _ => c.brand,
    };
    final Color fg = selected ? base : base.withValues(alpha: 0.75);

    // Active item: a soft teal glass pill with an accent edge and glow.
    final BoxDecoration? active = selected
        ? BoxDecoration(
            borderRadius: DsRadius.brMd,
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: <Color>[
                c.brand.withValues(alpha: 0.24),
                c.brand.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: c.brand.withValues(alpha: 0.38)),
            boxShadow: <BoxShadow>[BoxShadow(color: g.glow, blurRadius: 16)],
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DecoratedBox(
        decoration: active ?? const BoxDecoration(),
        child: Material(
        color: Colors.transparent,
        borderRadius: DsRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: DsRadius.brMd,
          hoverColor: c.textPrimary.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: compact ? DsSpacing.sm : DsSpacing.md - 2,
            ),
            child: Row(
              children: <Widget>[
                Icon(destination.icon, size: compact ? 18 : 20, color: fg),
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
                if (destination.isNew && !compact)
                  // Until the user first opens it.
                  Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) => ref
                            .watch(navSeenProvider)
                            .contains(destination.route)
                        ? const SizedBox.shrink()
                        : DsBadge(
                            label: AppLocalizations.of(context).badgeNew,
                            tone: DsBadgeTone.income,
                          ),
                  ),
              ],
            ),
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
      accent: c.brand,
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                  AppEnv.betaAllAccess
                      ? Icons.celebration_outlined
                      : Icons.workspace_premium_outlined,
                  size: 18,
                  color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  AppEnv.betaAllAccess ? l.betaTitle : l.upgradeTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(AppEnv.betaAllAccess ? l.betaAllUnlocked : l.upgradeSubtitle,
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: DsSpacing.md),
          if (AppEnv.betaAllAccess)
            DsButton(
              label: l.shareTabInvite,
              icon: Icons.group_add_outlined,
              variant: DsButtonVariant.secondary,
              expand: true,
              onPressed: () => ShareAppSheet.show(context),
            )
          else
            DsButton(
              label: l.upgradeCta,
              expand: true,
              onPressed: () => context.go('/plans'),
            ),
        ],
      ),
    );
  }
}
