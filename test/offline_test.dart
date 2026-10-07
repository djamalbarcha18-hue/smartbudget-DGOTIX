import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/network/connectivity.dart';
import 'package:smartbudget/features/shell/offline_banner.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget host(bool online) => ProviderScope(
      overrides: <Override>[
        onlineProvider.overrideWith((_) => Stream<bool>.value(online)),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: OfflineBanner(child: Scaffold(body: Text('content'))),
      ),
    );

void main() {
  testWidgets('offline: a note says the data is saved on this device',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();
    expect(find.text('Offline · saved on this device, syncs when back online'),
        findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('online: no note', (WidgetTester tester) async {
    await tester.pumpWidget(host(true));
    await tester.pump();
    expect(find.textContaining('Offline'), findsNothing);
  });

  group('web offline copy', () {
    final String sw = File('web/sw.js').readAsStringSync();
    final String finish = File('tool/finish_web_build.sh').readAsStringSync();

    test('the deploy can fill in the build, the engine and the assets', () {
      for (final String slot in <String>[
        "const BUILD = 'dev';",
        "const ENGINE = 'dev';",
        'const ASSETS = [];',
      ]) {
        expect(sw.split(slot).length - 1, 1, reason: slot);
        expect(finish, contains(slot), reason: slot);
      }
    });

    test('the update check and outside services are never served from it',
        () {
      expect(sw, contains("path === 'build.json'"));
      // Only Google's font files are kept from other sites.
      expect(sw, contains("FONT_HOSTS = ['fonts.gstatic.com', 'fonts.googleapis.com']"));
    });

    test('the page installs it and runs the engine from this site', () {
      final String html = File('web/index.html').readAsStringSync();
      expect(html, contains('<script src="offline.js"></script>'));
      expect(html, isNot(contains('www.gstatic.com')));
      expect(File('.github/workflows/deploy-web.yml').readAsStringSync(),
          contains('--no-web-resources-cdn'));
    });
  });
}
