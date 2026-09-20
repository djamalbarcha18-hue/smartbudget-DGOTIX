import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/analytics/application/alerts_controller.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/analytics/presentation/alert_presentation.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/shell/brand_controls.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
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
          const _MonthChip(),
          const SizedBox(width: DsSpacing.xs),
          const _YearChip(),
          const SizedBox(width: DsSpacing.xs),
          const _CurrencyChip(),
          const SizedBox(width: DsSpacing.xs),
          if (!isMobile) const LanguageToggleButton(),
          const ThemeToggleButton(),
          const _NotificationsBell(),
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

/// Compact pill used as the trigger for the top-bar selector menus.
class _ChipBox extends StatelessWidget {
  const _ChipBox({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
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
          Icon(icon, size: 15, color: c.textMuted),
          const SizedBox(width: DsSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}

const List<String> _monthsAr = <String>[
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const List<String> _monthsEn = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Global month selector — shared with Monthly Budget via [selectedMonthProvider].
class _MonthChip extends ConsumerWidget {
  const _MonthChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<String> names = ar ? _monthsAr : _monthsEn;
    final int month = ref.watch(selectedMonthProvider);
    final int value = (month >= 1 && month <= 12) ? month : DateTime.now().month;

    return PopupMenuButton<int>(
      tooltip: names[value - 1],
      offset: const Offset(0, 48),
      color: c.bgElevated,
      onSelected: (int v) =>
          ref.read(selectedMonthProvider.notifier).state = v,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        for (int m = 1; m <= 12; m++)
          PopupMenuItem<int>(value: m, child: Text(names[m - 1])),
      ],
      child: _ChipBox(
          icon: Icons.event_note_outlined, label: names[value - 1]),
    );
  }
}

/// Global year selector — shared with Dashboard / Reports / Monthly Budget via
/// [selectedYearProvider]. Lists the current year and the next nine.
class _YearChip extends ConsumerWidget {
  const _YearChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final int year = ref.watch(selectedYearProvider);
    final int now = DateTime.now().year;
    final List<int> years = List<int>.generate(10, (int i) => now + i);
    final int value = years.contains(year) ? year : now;

    return PopupMenuButton<int>(
      tooltip: '$value',
      offset: const Offset(0, 48),
      color: c.bgElevated,
      onSelected: (int v) =>
          ref.read(selectedYearProvider.notifier).state = v,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        for (final int y in years)
          PopupMenuItem<int>(value: y, child: Text('$y')),
      ],
      child: _ChipBox(icon: Icons.calendar_today_outlined, label: '$value'),
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

/// Notifications bell: shows the live alert count and lists the alerts (each
/// navigates to its page). Data-backed via [alertsProvider].
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool hasData = ref.watch(financeSummaryProvider).count > 0;
    final List<AppAlert> alerts =
        hasData ? ref.watch(alertsProvider) : const <AppAlert>[];
    final int count = alerts.length;

    return PopupMenuButton<int>(
      tooltip: l.alertsSection,
      offset: const Offset(0, 52),
      color: c.bgElevated,
      onSelected: (int i) => context.go(alerts[i].route),
      itemBuilder: (BuildContext ctx) {
        if (alerts.isEmpty) {
          return <PopupMenuEntry<int>>[
            PopupMenuItem<int>(
              enabled: false,
              child: SizedBox(
                width: 240,
                child: Text(l.alertsAllClear,
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
            ),
          ];
        }
        return <PopupMenuEntry<int>>[
          for (int i = 0; i < alerts.length && i < 8; i++)
            PopupMenuItem<int>(value: i, child: _AlertMenuRow(alert: alerts[i])),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(Icons.notifications_none_rounded, color: c.textMuted),
            if (count > 0)
              PositionedDirectional(
                end: -4,
                top: -4,
                child: _CountBadge(count: count, color: c.expense),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertMenuRow extends StatelessWidget {
  const _AlertMenuRow({required this.alert});
  final AppAlert alert;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AlertView v = describeAlert(context, alert);
    return SizedBox(
      width: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: v.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(v.title,
                    style: t.labelLarge?.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(v.description,
                    style: t.bodySmall?.copyWith(color: c.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: EdgeInsets.symmetric(horizontal: count > 9 ? 4 : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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
