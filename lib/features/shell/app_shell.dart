import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/search/app_search.dart';
import 'package:smartbudget/features/shell/app_footer.dart';
import 'package:smartbudget/features/shell/app_top_bar.dart';
import 'package:smartbudget/features/shell/nav_sidebar.dart';

/// Responsive application shell: persistent sidebar on desktop/tablet, a drawer
/// on mobile. Hosts the routed [child] with a top bar and a compact footer.
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

    final Widget content = Column(
      children: <Widget>[
        Builder(
          builder: (BuildContext ctx) => AppTopBar(
            onOpenMenu: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        Expanded(
          child: Container(
            color: c.bgPage,
            child: child,
          ),
        ),
        const AppFooter(),
      ],
    );

    if (isMobile) {
      return _withSearchShortcut(
        context,
        Scaffold(
          backgroundColor: c.bgPage,
          drawer: Drawer(
            width: 288,
            backgroundColor: c.bgElevated,
            child: NavSidebar(currentRoute: route, onSelect: go, width: 288),
          ),
          body: content,
        ),
      );
    }

    return _withSearchShortcut(
      context,
      Scaffold(
        backgroundColor: c.bgPage,
        body: Row(
          children: <Widget>[
            NavSidebar(
              currentRoute: route,
              onSelect: go,
              // A collapsed icon-rail for tablet is a future enhancement; for
              // now the full sidebar is shown on every non-mobile width.
              width: 264,
            ),
            Expanded(child: content),
          ],
        ),
      ),
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
