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

/// Notifications bell: a live alert count that opens a smoothly-animated panel
/// (fade + scale from the bell corner). Data-backed via [alertsProvider].
class _NotificationsBell extends ConsumerStatefulWidget {
  const _NotificationsBell();

  @override
  ConsumerState<_NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends ConsumerState<_NotificationsBell>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 190));
  OverlayEntry? _entry;

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _anim.dispose();
    super.dispose();
  }

  void _toggle() => _entry == null ? _open() : _close();

  void _open() {
    _entry = OverlayEntry(builder: (_) => _overlay());
    Overlay.of(context).insert(_entry!);
    _anim.forward();
    setState(() {});
  }

  Future<void> _close() async {
    if (_entry == null) return;
    try {
      await _anim.reverse();
    } catch (_) {
      // Controller may be disposed mid-animation; ignore.
    }
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  Future<void> _select(String route) async {
    await _close();
    if (mounted) context.go(route);
  }

  Widget _overlay() {
    final CurvedAnimation curved =
        CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: const SizedBox.shrink(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              alignment: Alignment.topRight,
              child: _NotificationsPanel(onSelect: _select),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool hasData = ref.watch(financeSummaryProvider).count > 0;
    final int count = hasData ? ref.watch(alertsProvider).length : 0;

    return CompositedTransformTarget(
      link: _link,
      child: Tooltip(
        message: l.alertsSection,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
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
        ),
      ),
    );
  }
}

/// The animated notifications panel content (kept live via a Consumer).
class _NotificationsPanel extends ConsumerWidget {
  const _NotificationsPanel({required this.onSelect});
  final void Function(String route) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool hasData = ref.watch(financeSummaryProvider).count > 0;
    final List<AppAlert> alerts =
        hasData ? ref.watch(alertsProvider) : const <AppAlert>[];
    final List<AppAlert> shown = alerts.take(8).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DsSpacing.lg, DsSpacing.md, DsSpacing.md, DsSpacing.md),
              child: Row(
                children: <Widget>[
                  Icon(Icons.notifications_active_outlined,
                      size: 18, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(child: Text(l.alertsSection, style: t.titleSmall)),
                  if (shown.isNotEmpty)
                    _CountBadge(count: alerts.length, color: c.expense),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(DsSpacing.xl),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: c.income),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Text(l.alertsAllClear,
                          style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(DsSpacing.sm),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (BuildContext ctx, int i) => _PanelAlertRow(
                    alert: shown[i],
                    onTap: () => onSelect(shown[i].route),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PanelAlertRow extends StatelessWidget {
  const _PanelAlertRow({required this.alert, required this.onTap});
  final AppAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AlertView v = describeAlert(context, alert);
    return InkWell(
      onTap: onTap,
      borderRadius: DsRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
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
            Icon(Icons.chevron_right_rounded, size: 16, color: c.textFaint),
          ],
        ),
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
