import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartbudget/core/update/app_update.dart';

AppUpdateChecker checkerServing(String? build, {int status = 200}) =>
    AppUpdateChecker(
      origin: Uri.parse('https://smartbudget.dgotix.com/'),
      client: MockClient((http.Request r) async {
        expect(r.url.path, '/build.json');
        expect(r.url.queryParameters['t'], isNotNull); // never a cached copy
        return http.Response(build == null ? 'oops' : '{"build":"$build"}', status);
      }),
    );

ProviderContainer containerWith(String running, AppUpdateChecker checker) =>
    ProviderContainer(overrides: <Override>[
      runningBuildIdProvider.overrideWithValue(running),
      appUpdateCheckerProvider.overrideWithValue(checker),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a newer deployed build makes an update available', () async {
    final ProviderContainer c = containerWith('aaa111', checkerServing('bbb222'));
    addTearDown(c.dispose);
    expect(c.read(appUpdateAvailableProvider), isFalse);
    await c.read(appUpdateAvailableProvider.notifier).check();
    expect(c.read(appUpdateAvailableProvider), isTrue);
  });

  test('the same build: nothing to update', () async {
    final ProviderContainer c = containerWith('aaa111', checkerServing('aaa111'));
    addTearDown(c.dispose);
    await c.read(appUpdateAvailableProvider.notifier).check();
    expect(c.read(appUpdateAvailableProvider), isFalse);
  });

  test('an unreadable answer never claims an update', () async {
    for (final AppUpdateChecker checker in <AppUpdateChecker>[
      checkerServing(null),
      checkerServing('bbb222', status: 404),
    ]) {
      final ProviderContainer c = containerWith('aaa111', checker);
      await c.read(appUpdateAvailableProvider.notifier).check();
      expect(c.read(appUpdateAvailableProvider), isFalse);
      c.dispose();
    }
  });

  test('builds without an id (mobile, local) do not check', () async {
    final ProviderContainer c = containerWith('', checkerServing('bbb222'));
    addTearDown(c.dispose);
    expect(c.read(appUpdateAvailableProvider), isFalse);
  });
}
