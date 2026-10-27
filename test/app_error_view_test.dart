import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/app_restart.dart';
import 'package:smartbudget/core/errors/app_error_view.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A part of a page that fails while drawing.
class _Broken extends StatelessWidget {
  const _Broken();
  @override
  Widget build(BuildContext context) => throw StateError('broken');
}

void main() {
  late ErrorWidgetBuilder before;
  late AppLocalizations l;
  setUp(() async {
    before = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails d) => AppErrorView(details: d);
    l = await AppLocalizations.delegate.load(const Locale('ar'));
  });
  tearDown(() => ErrorWidget.builder = before);

  Future<GoRouter> pump(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/dashboard',
      routes: <RouteBase>[
        GoRoute(
            path: '/dashboard',
            builder: (_, __) => const Scaffold(body: Text('home'))),
        GoRoute(
            path: '/budget',
            builder: (_, __) => const Scaffold(body: _Broken())),
        GoRoute(
          path: '/goals',
          builder: (_, __) => Scaffold(
            body: Column(children: const <Widget>[
              Text('goals'),
              SizedBox(width: 40, height: 40, child: _Broken()),
            ]),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        ...AppLocalizations.localizationsDelegates,
        ...fallbackLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a page that fails says so and offers the way home',
      (WidgetTester tester) async {
    final GoRouter r = await pump(tester);
    r.go('/budget');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isStateError);
    expect(find.text(l.errorPartTitle), findsOneWidget);
    await tester.tap(find.text(l.errorGoHome));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('failing inside a sheet: the sheet closes, home shows',
      (WidgetTester tester) async {
    final GoRouter r = await pump(tester);
    r.go('/goals');
    await tester.pumpAndSettle();
    tester.takeException(); // the small broken spot on the page
    showModalBottomSheet<void>(
      context: tester.element(find.text('goals')),
      builder: (_) => const SizedBox(height: 300, child: _Broken()),
    );
    await tester.pumpAndSettle();
    tester.takeException();
    await tester.tap(find.text(l.errorGoHome));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a small spot gets a quiet icon, the page stays usable',
      (WidgetTester tester) async {
    final GoRouter r = await pump(tester);
    r.go('/goals');
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.text('goals'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text(l.errorGoHome), findsNothing);
  });

  testWidgets('failing on the home page itself: the app starts again',
      (WidgetTester tester) async {
    int restarts = 0;
    AppRestart.register(() async => restarts++);
    final GoRouter r = await pump(tester);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () => AppErrorView.goHome(context),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(restarts, 1); // no router here: a clean start
    expect(r, isNotNull);
  });
}
