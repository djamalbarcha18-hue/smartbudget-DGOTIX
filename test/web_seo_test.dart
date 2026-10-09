import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Search engines and link previews read the page's head, robots.txt and
/// sitemap.xml; these checks keep them pointing at the live address.
void main() {
  const String site = 'https://smartbudget.dgotix.com/';
  final String html = File('web/index.html').readAsStringSync();

  test('the page is Arabic and describes the app in Arabic and English', () {
    expect(html, contains('<html lang="ar">'));
    expect(html, contains('<meta name="description" content="سمارت بدجت'));
    expect(html, contains('<link rel="canonical" href="$site">'));
    // English searchers find it too.
    expect(html, contains('SmartBudget: budget planner and expense tracker'));
    for (final String k in <String>['حاسبة الزكاة', 'محوّل العملات', 'الأعياد',
        'zakat calculator', 'currency converter', 'Eid']) {
      expect(html, contains(k));
    }
  });

  test('link previews have a title, description and an image that exists', () {
    for (final String p in <String>['og:title', 'og:description', 'og:url']) {
      expect(html, contains('property="$p"'));
    }
    expect(html, contains('content="${site}og-image.jpg"'));
    expect(File('web/og-image.jpg').existsSync(), isTrue);
  });

  test('robots.txt points to the sitemap, which lists the site', () {
    expect(File('web/robots.txt').readAsStringSync(),
        contains('Sitemap: ${site}sitemap.xml'));
    expect(File('web/sitemap.xml').readAsStringSync(),
        contains('<loc>$site</loc>'));
  });
}
