/// The exchange rates load and refresh after awaits. If the container ends
/// meanwhile (an account switch, a test) they must stop quietly: reading a
/// provider from a disposed container throws, and nothing awaits that error.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a container that ends during the first load does not throw', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final List<Object> errors = <Object>[];

    await runZonedGuarded(() async {
      final ProviderContainer c = ProviderContainer();
      c.read(ratesProvider); // starts the load and the live refresh
      c.dispose(); // the container ends before they finish
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }, (Object e, StackTrace s) => errors.add(e));

    expect(errors, isEmpty);
  });

  test('the rates still load when the container stays', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final Map<String, double> rates = c.read(ratesProvider);
    expect(rates['USD'], 1.0);
    expect(rates['DZD'], greaterThan(0));
  });
}
