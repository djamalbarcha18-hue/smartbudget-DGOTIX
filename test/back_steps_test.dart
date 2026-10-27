import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/features/shell/back_steps.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The app's navigation in small: pages inside a shell with a menu drawer,
/// opened with `go` as the menu does, and a detail page pushed over one.
GoRouter _router(
    {required bool withBackSteps,
    VoidCallback? onExit,
    String start = '/dashboard'}) {
  Widget page(String name) => Center(child: Text('page $name'));
  return GoRouter(
    initialLocation: start,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          final Widget shell = Scaffold(
            drawer: const Drawer(child: Text('menu')),
            body: child,
          );
          return withBackSteps
              ? BackSteps(
                  location: state.uri.toString(),
                  onExit: onExit,
                  child: shell,
                )
              : shell;
        },
        routes: <RouteBase>[
          for (final String p in <String>['dashboard', 'budget', 'goals'])
            GoRoute(path: '/$p', builder: (_, __) => page(p)),
          GoRoute(
            path: '/trips/:id',
            builder: (_, GoRouterState s) =>
                page('trip ${s.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
}

Future<GoRouter> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...fallbackLocalizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  await tester.pumpAndSettle();
  return router;
}

Future<void> _back(WidgetTester tester) async {
  // ignore: deprecated_member_use
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('before: pages opened from the menu, back closed the app',
      (WidgetTester tester) async {
    int closed = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'SystemNavigator.pop') closed++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final GoRouter r = await _pump(tester, _router(withBackSteps: false));
    r.go('/budget');
    await tester.pumpAndSettle();
    await _back(tester);
    expect(closed, 1);
  });

  testWidgets('back goes to the page before, a step at a time',
      (WidgetTester tester) async {
    int exits = 0;
    final GoRouter r = await _pump(
        tester, _router(withBackSteps: true, onExit: () => exits++));
    r.go('/budget');
    await tester.pumpAndSettle();
    r.go('/goals');
    await tester.pumpAndSettle();

    await _back(tester);
    expect(find.text('page budget'), findsOneWidget);
    await _back(tester);
    expect(find.text('page dashboard'), findsOneWidget);

    // Home: back leaves, as Android apps do; nothing to read first.
    await _back(tester);
    expect(exits, 1);
  });

  testWidgets('a page opened again: back never shows it twice',
      (WidgetTester tester) async {
    int exits = 0;
    final GoRouter r = await _pump(
        tester, _router(withBackSteps: true, onExit: () => exits++));
    for (final String p in <String>['/budget', '/goals', '/budget']) {
      r.go(p);
      await tester.pumpAndSettle();
    }
    await _back(tester);
    expect(find.text('page dashboard'), findsOneWidget);
    await _back(tester);
    expect(exits, 1);
  });

  testWidgets('the menu open: back closes it, the page stays',
      (WidgetTester tester) async {
    final GoRouter r = await _pump(tester, _router(withBackSteps: true));
    r.go('/budget');
    await tester.pumpAndSettle();
    final ScaffoldState scaffold =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('menu'), findsOneWidget);

    await _back(tester);
    expect(find.text('menu'), findsNothing);
    expect(find.text('page budget'), findsOneWidget);
  });

  testWidgets('a page pushed over another closes back to it',
      (WidgetTester tester) async {
    final GoRouter r = await _pump(tester, _router(withBackSteps: true));
    r.go('/budget');
    await tester.pumpAndSettle();
    r.push('/trips/7');
    await tester.pumpAndSettle();
    expect(find.text('page trip 7'), findsOneWidget);

    await _back(tester);
    expect(find.text('page budget'), findsOneWidget);
  });

  testWidgets('opened straight on a page (a link, a reminder): back goes home',
      (WidgetTester tester) async {
    await _pump(tester, _router(withBackSteps: true, start: '/goals'));
    await _back(tester);
    expect(find.text('page dashboard'), findsOneWidget);
  });

  testWidgets('a sheet open: back closes it first',
      (WidgetTester tester) async {
    final GoRouter r = await _pump(tester, _router(withBackSteps: true));
    r.go('/budget');
    await tester.pumpAndSettle();
    showModalBottomSheet<void>(
      context: tester.element(find.text('page budget')),
      builder: (_) => const Text('sheet'),
    );
    await tester.pumpAndSettle();
    await _back(tester);
    expect(find.text('sheet'), findsNothing);
    expect(find.text('page budget'), findsOneWidget);
  });
}
