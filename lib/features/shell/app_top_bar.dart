import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_badge.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_panel.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/analytics/application/alerts_controller.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/analytics/presentation/alert_presentation.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/notifications/application/notifications_controller.dart';
import 'package:smartbudget/features/notifications/domain/notification_feed.dart';
import 'package:smartbudget/features/search/app_search.dart';
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

    return GlassPanel(
      borderRadius: DsRadius.brLg,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? DsSpacing.xs : DsSpacing.md),
      child: SizedBox(
      height: 60,
      child: isMobile ? _mobile(context, c) : Row(
        children: <Widget>[
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
      ),
    );
  }

  /// Phone layout: menu and the always-needed actions stay pinned; the period
  /// and currency selectors (plus search and theme) scroll sideways instead of
  /// overflowing the bar.
  Widget _mobile(BuildContext context, DsColors c) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onOpenMenu,
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: Icon(Icons.menu_rounded, color: c.textMuted),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                const _MonthChip(),
                const SizedBox(width: DsSpacing.xs),
                const _YearChip(),
                const SizedBox(width: DsSpacing.xs),
                const _CurrencyChip(),
                IconButton(
                  onPressed: () => AppSearchDialog.show(context),
                  tooltip: AppLocalizations.of(context).searchHint,
                  icon: Icon(Icons.search_rounded, color: c.textMuted),
                ),
                const ThemeToggleButton(),
              ],
            ),
          ),
        ),
        const _NotificationsBell(),
        const _ProfileChip(),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return Material(
      color: c.surfaceMuted,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        onTap: () => AppSearchDialog.show(context),
        borderRadius: DsRadius.brMd,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          decoration: BoxDecoration(
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
                child: Text('Ctrl K',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
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

/// Global month selector — shared with Monthly Budget via [selectedMonthProvider].
class _MonthChip extends ConsumerWidget {
  const _MonthChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<String> names = MonthNames.full(ar: ar);
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
    final List<Currency> currencies = ref.watch(currenciesByStrengthProvider);

    return PopupMenuButton<String>(
      tooltip: l.baseCurrency,
      offset: const Offset(0, 48),
      color: c.bgElevated,
      onSelected: (String v) =>
          ref.read(baseCurrencyProvider.notifier).set(v),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final Currency x in currencies)
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

/// Notifications bell: the count of NEW notifications, opening a
/// smoothly-animated panel (fade + scale from the bell corner). Opening the
/// panel marks what it shows as seen; new ones arrive as the data, the date or
/// the month changes. Data-backed via [notificationsProvider].
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

  /// What was unread when the panel opened, so those rows stay marked "new"
  /// while the user reads them.
  Set<String> _newIds = const <String>{};

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _anim.dispose();
    super.dispose();
  }

  void _toggle() => _entry == null ? _open() : _close();

  void _markAllSeen() {
    ref.read(seenNotificationsProvider.notifier).markSeen(
        ref.read(notificationsProvider).map((FeedItem f) => f.id));
  }

  void _open() {
    _newIds = ref.read(unreadNotificationsProvider);
    _markAllSeen();
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
    if (mounted) {
      // Anything that arrived while the panel was open has been seen too.
      _markAllSeen();
      setState(() {});
    }
  }

  Future<void> _openDetail(AppAlert alert) async {
    await _close();
    if (mounted) await _AlertDetailDialog.show(context, alert, _goToAlert);
  }

  /// One-press navigation straight from a panel row: close the panel, then go.
  Future<void> _goDirect(AppAlert alert) async {
    await _close();
    if (mounted) _goToAlert(alert);
  }

  Future<void> _goPlans() async {
    await _close();
    if (mounted) context.go('/plans');
  }

  void _goToAlert(AppAlert alert) {
    // Set a highlight target the destination page picks up, then navigate.
    ref.read(alertFocusProvider.notifier).state =
        AlertFocus(route: alert.route, key: alert.focusKey);
    context.go(alert.route);
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) ref.read(alertFocusProvider.notifier).state = null;
    });
  }

  Widget _overlay() {
    // Anchor to the side the bell sits on, so the panel opens INTO the screen
    // (in RTL the bell is near the left edge, in LTR near the right).
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
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
          targetAnchor: rtl ? Alignment.bottomLeft : Alignment.bottomRight,
          followerAnchor: rtl ? Alignment.topLeft : Alignment.topRight,
          offset: const Offset(0, 8),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              alignment: rtl ? Alignment.topLeft : Alignment.topRight,
              child: _NotificationsPanel(
                  newIds: _newIds,
                  onOpen: _openDetail,
                  onGo: _goDirect,
                  onPlans: _goPlans),
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
    final int count = ref.watch(unreadNotificationsProvider).length;

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
  const _NotificationsPanel({
    required this.newIds,
    required this.onOpen,
    required this.onGo,
    required this.onPlans,
  });
  final Set<String> newIds;
  final VoidCallback onPlans;
  final void Function(AppAlert alert) onOpen;
  final void Function(AppAlert alert) onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final List<FeedItem> items = ref.watch(notificationsProvider);
    // New ones first, then the rest (each group keeps its urgency order).
    final List<FeedItem> shown = <FeedItem>[
      ...items.where((FeedItem f) => newIds.contains(f.id)),
      ...items.where((FeedItem f) => !newIds.contains(f.id)),
    ].take(8).toList();
    final bool smartLocked =
        !ref.watch(featureGateProvider(Feature.smartAlerts)).allowed;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: math.min(340.0, MediaQuery.sizeOf(context).width - 24),
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
                    _CountBadge(count: items.length, color: c.expense),
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
                    alert: shown[i].alert,
                    isNew: newIds.contains(shown[i].id),
                    onTap: () => onOpen(shown[i].alert),
                    onGo: () => onGo(shown[i].alert),
                  ),
                ),
              ),
            if (smartLocked) ...<Widget>[
              Divider(height: 1, color: c.border),
              InkWell(
                onTap: onPlans,
                child: Padding(
                  padding: const EdgeInsets.all(DsSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.auto_awesome_outlined,
                          size: 18, color: c.brand),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l.smartAlertsTitle,
                                style: t.labelLarge
                                    ?.copyWith(color: c.textPrimary)),
                            const SizedBox(height: 2),
                            Text(l.smartAlertsLocked,
                                style: t.bodySmall
                                    ?.copyWith(color: c.textMuted)),
                            const SizedBox(height: 4),
                            Text(l.smartAlertsSeePlans,
                                style: t.labelMedium?.copyWith(
                                    color: c.brand,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanelAlertRow extends StatelessWidget {
  const _PanelAlertRow({
    required this.alert,
    required this.isNew,
    required this.onTap,
    required this.onGo,
  });
  final AppAlert alert;

  /// Unread when the panel opened: tinted, with a "New" tag.
  final bool isNew;

  /// Tapping the row body opens the large detail view.
  final VoidCallback onTap;

  /// Pressing the trailing action navigates straight to the alert's page.
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AlertView v = describeAlert(context, alert);
    return Ink(
      decoration: BoxDecoration(
        color: isNew ? c.brand.withValues(alpha: 0.07) : null,
        borderRadius: DsRadius.brMd,
      ),
      child: InkWell(
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
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(v.title,
                            style: t.labelLarge?.copyWith(
                                color: c.textPrimary,
                                fontWeight:
                                    isNew ? FontWeight.w700 : null)),
                      ),
                      if (isNew) ...<Widget>[
                        const SizedBox(width: 6),
                        DsBadge(
                            label: AppLocalizations.of(context)
                                .notificationsNew,
                            tone: DsBadgeTone.brand),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(v.description,
                      style: t.bodySmall?.copyWith(color: c.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.xs),
            // One-press navigation to the alert's own page.
            Tooltip(
              message: v.actionLabel,
              child: InkWell(
                onTap: onGo,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: c.brand),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A large, centered detail view for a single alert, shown when a notification
/// is tapped.
class _AlertDetailDialog extends StatelessWidget {
  const _AlertDetailDialog({required this.alert, required this.onGo});
  final AppAlert alert;
  final void Function(AppAlert alert) onGo;

  static Future<void> show(
    BuildContext context,
    AppAlert alert,
    void Function(AppAlert alert) onGo,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) => _AlertDetailDialog(alert: alert, onGo: onGo),
      );

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AlertView v = describeAlert(context, alert);

    return Dialog(
      backgroundColor: c.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: v.color.withValues(alpha: 0.30)),
                    ),
                    child: Icon(v.icon, color: v.color, size: 24),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(child: Text(v.title, style: t.titleLarge)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.lg),
              Text(
                v.description,
                style: t.bodyLarge?.copyWith(color: c.textPrimary, height: 1.55),
              ),
              const SizedBox(height: DsSpacing.xl),
              DsButton(
                label: v.actionLabel,
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onGo(alert);
                },
              ),
            ],
          ),
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
