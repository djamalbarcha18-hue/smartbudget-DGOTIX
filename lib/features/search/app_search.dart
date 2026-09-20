import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// One search hit: an icon, a title, an optional subtitle and the route to open.
class _Hit {
  const _Hit({
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;
}

/// A lightweight command palette: jump to any page, or find a transaction or
/// goal by name/category. Data-backed (no fabricated results); opens from the
/// top-bar search field or Ctrl/⌘+K.
class AppSearchDialog extends ConsumerStatefulWidget {
  const AppSearchDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.38),
        builder: (_) => const AppSearchDialog(),
      );

  @override
  ConsumerState<AppSearchDialog> createState() => _AppSearchDialogState();
}

class _AppSearchDialogState extends ConsumerState<AppSearchDialog> {
  final TextEditingController _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openHit(_Hit hit) {
    Navigator.of(context).pop();
    context.go(hit.route);
  }

  List<(String, List<_Hit>)> _groups(AppLocalizations l, bool ar) {
    final String q = _q.trim().toLowerCase();
    final List<(String, List<_Hit>)> out = <(String, List<_Hit>)>[];

    // Pages — always available (empty query lists them all as quick nav).
    final List<_Hit> pages = <_Hit>[
      for (final NavDestination d in AppNav.destinations)
        if (q.isEmpty || d.label(l).toLowerCase().contains(q))
          _Hit(icon: d.icon, title: d.label(l), route: d.route),
    ];
    if (pages.isNotEmpty) out.add((l.searchGroupPages, pages));

    if (q.isNotEmpty) {
      // Transactions — by description or category.
      final List<Transaction> txns =
          ref.read(transactionsProvider).valueOrNull ?? const <Transaction>[];
      final List<_Hit> txHits = <_Hit>[];
      for (final Transaction t in txns) {
        final String cat = Catalog.label(t.category, ar: ar);
        final bool match = t.description.toLowerCase().contains(q) ||
            cat.toLowerCase().contains(q);
        if (match) {
          txHits.add(_Hit(
            icon: Icons.receipt_long_outlined,
            title: t.description.isEmpty ? cat : t.description,
            subtitle: '$cat · ${MoneyFormatter.format(t.amount)}',
            route: '/transactions',
          ));
        }
        if (txHits.length >= 6) break;
      }
      if (txHits.isNotEmpty) out.add((l.searchGroupTransactions, txHits));

      // Goals — by name.
      final List<Goal> goals =
          ref.read(goalsProvider).valueOrNull ?? const <Goal>[];
      final List<_Hit> goalHits = <_Hit>[
        for (final Goal g in goals)
          if (g.name.toLowerCase().contains(q))
            _Hit(
                icon: Icons.flag_outlined,
                title: g.name,
                subtitle: MoneyFormatter.format(g.target),
                route: '/goals'),
      ];
      if (goalHits.isNotEmpty) {
        out.add((l.searchGroupGoals, goalHits.take(5).toList()));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final List<(String, List<_Hit>)> groups = _groups(l, ar);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg, vertical: 72),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                decoration: BoxDecoration(
                  color: c.bgElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Search input.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(DsSpacing.md,
                          DsSpacing.sm, DsSpacing.sm, DsSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.search_rounded,
                              size: 20, color: c.textMuted),
                          const SizedBox(width: DsSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: l.searchHint,
                              ),
                              onChanged: (String v) => setState(() => _q = v),
                              onSubmitted: (_) {
                                if (groups.isNotEmpty &&
                                    groups.first.$2.isNotEmpty) {
                                  _openHit(groups.first.$2.first);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: c.border),
                    Flexible(
                      child: groups.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(DsSpacing.xl),
                              child: Text(l.searchNoResults,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: c.textMuted)),
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  vertical: DsSpacing.sm),
                              children: <Widget>[
                                for (final (String, List<_Hit>) g in groups) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        DsSpacing.lg,
                                        DsSpacing.sm,
                                        DsSpacing.lg,
                                        DsSpacing.xs),
                                    child: Text(
                                      g.$1.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: c.textFaint,
                                              letterSpacing: 0.6),
                                    ),
                                  ),
                                  for (final _Hit hit in g.$2)
                                    _HitRow(hit: hit, onTap: () => _openHit(hit)),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.onTap});
  final _Hit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.lg, vertical: DsSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(hit.icon, size: 18, color: c.brand),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(hit.title,
                      style: t.bodyMedium?.copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (hit.subtitle != null)
                    Text(hit.subtitle!,
                        style: t.bodySmall?.copyWith(color: c.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.north_east_rounded, size: 14, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
