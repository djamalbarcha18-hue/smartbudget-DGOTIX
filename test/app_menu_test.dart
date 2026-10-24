import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/shell/nav_destinations.dart';

void main() {
  test('every page is in the menu once, or reached from one that is', () {
    final List<AppSection> shown = <AppSection>[
      ...AppMenu.main,
      for (final List<AppSection> f in AppMenu.folds.values) ...f,
      ...AppMenu.footer,
    ];
    expect(shown.toSet().length, shown.length); // no item twice
    for (final AppSection s in AppSection.values) {
      if (s == AppSection.plans) continue; // the upgrade card
      expect(shown.contains(s) || AppMenu.within.containsKey(s), isTrue,
          reason: '$s');
    }
  });

  test('a short menu: seven items first, the rest folded', () {
    expect(AppMenu.main.length, lessThanOrEqualTo(7));
    expect(AppMenu.main.first, AppSection.dashboard);
  });

  test('the page shown lights its item and opens its fold', () {
    expect(AppMenu.selectedFor('/'), AppSection.dashboard);
    expect(AppMenu.selectedFor('/expenses'), AppSection.transactions);
    expect(AppMenu.selectedFor('/guide'), AppSection.helpSupport);
    expect(AppMenu.selectedFor('/zakat'), AppSection.zakat);
    expect(AppMenu.foldOf(AppSection.zakat), NavFold.occasions);
    expect(AppMenu.foldOf(AppSection.debts), NavFold.tools);
    expect(AppMenu.foldOf(AppSection.dashboard), isNull);
  });
}
