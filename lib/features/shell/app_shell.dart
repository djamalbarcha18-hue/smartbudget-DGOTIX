import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/ds_backdrop.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/search/app_search.dart';
import 'package:smartbudget/features/shell/app_footer.dart';
import 'package:smartbudget/features/shell/app_top_bar.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/features/shell/nav_seen.dart';
import 'package:smartbudget/features/shell/nav_sidebar.dart';
import 'package:smartbudget/features/quick_entry/presentation/shared_text_listener.dart';
import 'package:smartbudget/features/reminders/presentation/reminder_section.dart';

/// Responsive application shell: a floating glass sidebar on desktop/tablet,
/// a drawer on mobile, a floating glass top bar and a compact footer — all
/// over the ambient [DsBackdrop]. Every glass surface inside shares one
/// [BackdropGroup], so their blurs cost a single backdrop pass.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final String route = GoRouterState.of(context).uri.path;
    final bool isMobile = context.isMobile;

    void go(String r) {
      context.go(r);
      if (isMobile) Navigator.of(context).maybePop(); // close drawer
    }

    final double inset = isMobile ? 8 : 12;
    final Widget content = Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              isMobile ? inset : 0, inset, inset, 0),
          child: Builder(
            builder: (BuildContext ctx) => AppTopBar(
              onOpenMenu: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        Expanded(child: child),
        _MarkSeen(route: route),
        // Phones keep the whole screen for the page; the legal and help
        // links are in Support, in the menu.
        if (!isMobile) const AppFooter(),
      ],
    );

    // A tap on the daily reminder opens quick entry here, and a bank
    // message shared with the app opens a filled-in transaction.
    Widget scene(Widget scaffold) => ReminderTapListener(
          child: SharedTextListener(
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: DsBackdrop()),
                BackdropGroup(child: scaffold),
              ],
            ),
          ),
        );

    if (isMobile) {
      return _withSearchShortcut(
        context,
        scene(Scaffold(
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            width: 288,
            backgroundColor: c.bgElevated,
            child: NavSidebar(currentRoute: route, onSelect: go, width: 288),
          ),
          // Android draws the app under the status and navigation bars
          // (edge to edge); the backdrop fills them, the content stays clear.
          body: SafeArea(child: content),
        )),
      );
    }

    return _withSearchShortcut(
      context,
      scene(Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(inset),
              child: NavSidebar(
                currentRoute: route,
                onSelect: go,
                floating: true,
                // A collapsed icon-rail for tablet is a future enhancement;
                // for now the full sidebar is shown on every non-mobile width.
                width: 256,
              ),
            ),
            Expanded(child: content),
          ],
        ),
      )),
    );
  }

  /// Wraps the shell so Ctrl+K / ⌘+K opens the command palette from anywhere.
  Widget _withSearchShortcut(BuildContext context, Widget child) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            AppSearchDialog.show(context),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            AppSearchDialog.show(context),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// Opening a page marked "new" in the menu takes its badge away.
class _MarkSeen extends ConsumerWidget {
  const _MarkSeen({required this.route});
  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool fresh = AppNav.destinations
            .any((NavDestination d) => d.isNew && d.route == route) &&
        !ref.watch(navSeenProvider).contains(route);
    if (fresh) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(navSeenProvider.notifier).markSeen(route));
    }
    return const SizedBox.shrink();
  }
}
