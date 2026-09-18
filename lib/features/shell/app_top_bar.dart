import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/shell/brand_controls.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Top application bar: menu (mobile) + search + actions (language, theme,
/// notifications, profile). Purely presentational in P1 — no fabricated data.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, this.onOpenMenu});

  /// On small screens, opens the navigation drawer.
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool isMobile = context.isMobile;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: c.bgElevated,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
      child: Row(
        children: <Widget>[
          if (isMobile)
            IconButton(
              onPressed: onOpenMenu,
              icon: Icon(Icons.menu_rounded, color: c.textMuted),
            ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: const _SearchField(),
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          const _CurrencyChip(),
          const SizedBox(width: DsSpacing.xs),
          if (!isMobile) const LanguageToggleButton(),
          const ThemeToggleButton(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_rounded, color: c.textMuted),
          ),
          const SizedBox(width: DsSpacing.xs),
          const _ProfileChip(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, size: 18, color: c.textFaint),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              l.searchHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius: DsRadius.brSm,
              border: Border.all(color: c.border),
            ),
            child: Text('Ctrl K', style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

/// Quick selector for the template (base) currency — flag + code + menu.
/// Changing it updates every money value across the app (symbol shown in front).
class _CurrencyChip extends ConsumerWidget {
  const _CurrencyChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final String code = ref.watch(baseCurrencyProvider);
    final Currency cur = Currencies.byCode(code);

    return PopupMenuButton<String>(
      tooltip: l.baseCurrency,
      offset: const Offset(0, 48),
      color: c.bgElevated,
      onSelected: (String v) =>
          ref.read(baseCurrencyProvider.notifier).set(v),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final Currency x in Currencies.all)
          PopupMenuItem<String>(
            value: x.code,
            child: Row(
              children: <Widget>[
                CurrencyFlag(x, width: 20),
                const SizedBox(width: DsSpacing.sm),
                Text('${x.code} · ${x.symbol}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
      ],
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DsSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: DsRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CurrencyFlag(cur, width: 18),
            const SizedBox(width: DsSpacing.xs),
            Text(cur.code, style: Theme.of(context).textTheme.labelLarge),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends ConsumerWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final String? name = ref.watch(authControllerProvider).user?.name;

    return PopupMenuButton<String>(
      tooltip: name ?? '',
      offset: const Offset(0, 48),
      color: c.bgElevated,
      onSelected: (String value) {
        if (value == 'signout') {
          ref.read(authControllerProvider.notifier).signOut();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (name != null)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(name, style: Theme.of(context).textTheme.titleSmall),
          ),
        PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: <Widget>[
              Icon(Icons.logout_rounded, size: 18, color: c.textMuted),
              const SizedBox(width: DsSpacing.sm),
              Text(l.authSignOut),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: c.brand.withValues(alpha: 0.18),
        child: Icon(Icons.person_outline_rounded, size: 18, color: c.brand),
      ),
    );
  }
}
