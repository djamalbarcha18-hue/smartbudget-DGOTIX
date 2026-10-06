import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The web page's Content-Security-Policy (web/index.html) blocks every
/// connection it doesn't list, so a source the app calls but the policy
/// forgets fails only in the browser. These checks catch that here.
void main() {
  final String html = File('web/index.html').readAsStringSync();
  final RegExpMatch? policy =
      RegExp(r'Content-Security-Policy" content="([^"]*)"').firstMatch(html);
  final Map<String, List<String>> directives = <String, List<String>>{
    for (final String d in (policy?.group(1) ?? '').split(';'))
      if (d.trim().isNotEmpty)
        d.trim().split(RegExp(r'\s+')).first:
            d.trim().split(RegExp(r'\s+')).skip(1).toList(),
  };
  final List<String> connect = directives['connect-src'] ?? <String>[];

  test('the page declares a policy', () {
    expect(policy, isNotNull);
    expect(directives['default-src'], <String>["'self'"]);
    expect(directives['object-src'], <String>["'none'"]);
  });

  test('scripts can come only from the site and Flutter, never inline', () {
    expect(directives['script-src'], isNot(contains("'unsafe-inline'")));
    expect(directives['script-src'], isNot(contains("'unsafe-eval'")));
  });

  test('the only page that may be framed is the site\'s own sign-in check', () {
    expect(directives['frame-src'], <String>["'self'"]);
  });

  test('the sign-in check page runs only its own script and Cloudflare\'s', () {
    final String page = File('web/turnstile.html').readAsStringSync();
    final RegExpMatch? p =
        RegExp(r'Content-Security-Policy" content="([^"]*)"').firstMatch(page);
    final Map<String, List<String>> d = <String, List<String>>{
      for (final String x in (p?.group(1) ?? '').split(';'))
        if (x.trim().isNotEmpty)
          x.trim().split(RegExp(r'\s+')).first:
              x.trim().split(RegExp(r'\s+')).skip(1).toList(),
    };
    expect(d['default-src'], <String>["'none'"]);
    expect(d['script-src'], <String>["'self'", 'https://challenges.cloudflare.com']);
    expect(d['frame-src'], <String>['https://challenges.cloudflare.com']);
    // No inline script: the logic is in turnstile.js.
    expect(RegExp(r'<script>').hasMatch(page), isFalse);
    // The token goes only to a page of this same site.
    expect(File('web/turnstile.js').readAsStringSync(),
        contains('postMessage(msg, location.origin)'));
  });

  test('a picked photo can be read (receipt scanner on the web)', () {
    // image_picker hands the photo over as a blob: URL read by XHR.
    expect(connect, contains('blob:'));
  });

  test('every outside source the app calls is allowed', () {
    final Set<String> called = <String>{};
    final RegExp url = RegExp(r'''['"](https://[a-z0-9.-]+\.[a-z]{2,})[/'"]''');
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      // Data the app fetches lives in the data layers; links it only opens
      // (share, support) live elsewhere and need no connection.
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (!f.path.contains('/data/')) continue;
      for (final RegExpMatch m in url.allMatches(f.readAsStringSync())) {
        called.add(m.group(1)!);
      }
    }
    expect(called, isNotEmpty);
    for (final String origin in called) {
      expect(connect, contains(origin), reason: '$origin is called by the app');
    }
  });
}
