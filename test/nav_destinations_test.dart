import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/shell/nav_destinations.dart';

void main() {
  test('every destination has a unique, non-empty route', () {
    final Set<String> routes = <String>{};
    for (final NavDestination d in AppNav.destinations) {
      expect(d.route.startsWith('/'), isTrue, reason: d.route);
      expect(routes.add(d.route), isTrue, reason: 'duplicate ${d.route}');
    }
  });

  test('settings and support are wired to their routes', () {
    String routeOf(AppSection s) =>
        AppNav.destinations.firstWhere((NavDestination d) => d.section == s).route;
    expect(routeOf(AppSection.settings), '/settings');
    expect(routeOf(AppSection.helpSupport), '/support');
  });

  test('every AppSection appears exactly once in the nav', () {
    for (final AppSection s in AppSection.values) {
      final int count =
          AppNav.destinations.where((NavDestination d) => d.section == s).length;
      expect(count, 1, reason: '$s appears $count times');
    }
  });
}
