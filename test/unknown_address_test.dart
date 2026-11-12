import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The router sends an address it has no page for (e.g. the data a sign-in
/// provider leaves after the «#») to the start, instead of «Page Not Found».
/// Same rule as lib/core/router/app_router.dart.
void main() {
  testWidgets('an unknown address lands on the start page', (tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/sb',
      onException: (_, __, GoRouter r) => r.go('/'),
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const Text('start')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('start'), findsOneWidget);
    expect(find.textContaining('no routes'), findsNothing);
  });
}
