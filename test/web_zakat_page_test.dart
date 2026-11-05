import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

/// The static zakat page (web/zakat/): readable by search engines, private,
/// and its sum is the app's sum.
void main() {
  final String html = File('web/zakat/index.html').readAsStringSync();
  final String visible = html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>'), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>'), '')
      .replaceAll(RegExp(r'<head>[\s\S]*?</head>'), '');

  group('the page', () {
    test('is Arabic, right to left, with a title, a heading and a canonical',
        () {
      expect(html, contains('<html lang="ar" dir="rtl">'));
      expect(html, contains('<title>حاسبة الزكاة'));
      expect(html, contains('<h1>حاسبة الزكاة'));
      expect(
          html,
          contains(
              'rel="canonical" href="https://smartbudget.dgotix.com/zakat/"'));
    });

    test('writes the name SmartBudget in Latin letters in what a reader sees',
        () {
      expect(visible, contains('SmartBudget'));
      expect(visible, isNot(contains('سمارت')));
      // Only the search description carries the Arabic spellings, on purpose.
      final String description = RegExp(r'name="description" content="([^"]*)"')
          .firstMatch(html)!
          .group(1)!;
      expect(description, contains('سمارت بدجت'));
      expect(description, contains('سمارت بادجت'));
    });

    test('sends nothing anywhere and loads nothing from outside', () {
      final String csp = RegExp(r'Content-Security-Policy" content="([^"]*)"')
          .firstMatch(html)!
          .group(1)!;
      expect(csp, contains("default-src 'none'"));
      expect(csp, isNot(contains('connect-src')));
      expect(csp, contains("script-src 'self'"));
      expect(
          RegExp(r'<(script|link|img|iframe)[^>]*(src|href)="https?:')
              .allMatches(html)
              .where((RegExpMatch m) => !m.group(0)!.contains('canonical'))
              .toList(),
          isEmpty);
      expect(html, isNot(contains('fetch(')));
      expect(File('web/zakat/ui.js').readAsStringSync(),
          isNot(anyOf(contains('fetch('), contains('XMLHttpRequest'))));
    });

    test('has structured data that parses, and every FAQ is on the page', () {
      final String raw =
          RegExp(r'<script type="application/ld\+json">([\s\S]*?)</script>')
              .firstMatch(html)!
              .group(1)!;
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> graph = data['@graph'] as List<dynamic>;
      final Map<String, dynamic> faq = graph
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> n) => n['@type'] == 'FAQPage');
      final List<dynamic> questions = faq['mainEntity'] as List<dynamic>;
      expect(questions.length, 4);
      for (final Map<String, dynamic> q
          in questions.cast<Map<String, dynamic>>()) {
        expect(visible, contains(q['name'] as String),
            reason: 'the question must be visible on the page');
      }
    });

    test('is listed in the sitemap', () {
      expect(File('web/sitemap.xml').readAsStringSync(),
          contains('<loc>https://smartbudget.dgotix.com/zakat/</loc>'));
    });

    test('says plainly that it is a tool, not a fatwa', () {
      expect(visible, contains('ليست فتوى'));
    });
  });

  group('its sum is the app\'s sum', () {
    final bool haveNode = () {
      try {
        return Process.runSync('node', <String>['--version']).exitCode == 0;
      } catch (_) {
        return false;
      }
    }();

    // A few hundred cases around the boundaries and at random.
    final Random rnd = Random(20261104);
    String amt([int max = 50000]) =>
        (rnd.nextInt(max * 100) / 100).toStringAsFixed(2);
    final List<Map<String, Object>> cases = <Map<String, Object>>[
      for (int n = 0; n < 300; n++)
        <String, Object>{
          'standard': rnd.nextBool() ? 'gold' : 'silver',
          'goldPrice': rnd.nextInt(10) == 0 ? '0' : amt(400),
          'silverPrice': rnd.nextInt(10) == 0 ? '0' : amt(8),
          'cash': amt(),
          'metals': rnd.nextBool() ? '0' : amt(20000),
          'trade': rnd.nextBool() ? '0' : amt(20000),
          'receivables': rnd.nextBool() ? '0' : amt(5000),
          'liabilities': rnd.nextBool() ? '0' : amt(30000),
          'hawl': rnd.nextBool(),
        },
      // Exactly at the nisab, and a cent under it.
      <String, Object>{
        'standard': 'gold',
        'goldPrice': '100.00',
        'silverPrice': '1.00',
        'cash': '8500.00',
        'metals': '0',
        'trade': '0',
        'receivables': '0',
        'liabilities': '0',
        'hawl': true,
      },
      <String, Object>{
        'standard': 'gold',
        'goldPrice': '100.00',
        'silverPrice': '1.00',
        'cash': '8499.99',
        'metals': '0',
        'trade': '0',
        'receivables': '0',
        'liabilities': '0',
        'hawl': true,
      },
    ];

    test('300+ inputs give the same amount due as the app', () {
      final ProcessResult r = Process.runSync('node', <String>[
        '-e',
        '''
const z = require('./web/zakat/zakat.js');
const cases = ${jsonEncode(cases)};
console.log(JSON.stringify(cases.map((c) => {
  const r = z.computeZakat({
    standard: c.standard, goldPrice: c.goldPrice, silverPrice: c.silverPrice,
    cash: c.cash, metals: c.metals, trade: c.trade,
    receivables: c.receivables, liabilities: c.liabilities,
    hawlComplete: c.hawl,
  });
  return {due: Math.round(r.due * 100), state: r.state, net: Math.round(r.net * 100)};
})));
''',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final List<dynamic> js = jsonDecode(r.stdout as String) as List<dynamic>;
      expect(js.length, cases.length);

      int minor(Object s) => (double.parse(s as String) * 100).round();
      for (int i = 0; i < cases.length; i++) {
        final Map<String, Object> c = cases[i];
        final ZakatResult app = ZakatCalculator.compute(ZakatInput(
          currency: 'USD',
          standard: c['standard'] == 'silver'
              ? ZakatStandard.silver
              : ZakatStandard.gold,
          goldPricePerGram: double.parse(c['goldPrice'] as String),
          silverPricePerGram: double.parse(c['silverPrice'] as String),
          savingsMinor: minor(c['cash']!),
          surplusMinor: 0,
          receivablesMinor: minor(c['receivables']!),
          liabilitiesMinor: minor(c['liabilities']!),
          portfolioMinor: minor(c['trade']!),
          manualMinor: minor(c['metals']!),
        ));
        final int appDue = c['hawl'] == true ? app.due.minorUnits : 0;
        final Map<String, dynamic> page = js[i] as Map<String, dynamic>;
        expect(page['net'], app.netZakatable.minorUnits,
            reason: 'net, case $i: $c');
        expect(page['due'], appDue, reason: 'due, case $i: $c');
      }
    }, skip: haveNode ? false : 'node is not installed');
  });
}
