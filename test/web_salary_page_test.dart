import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/salary_split/domain/salary_split.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The static salary-split page (web/salary-split/): readable by search
/// engines, private, and its sum is the app's sum.
void main() {
  final String html = File('web/salary-split/index.html').readAsStringSync();
  final String visible = html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>'), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>'), '')
      .replaceAll(RegExp(r'<head>[\s\S]*?</head>'), '');

  group('the page', () {
    test('is Arabic, right to left, with a title, a heading and a canonical',
        () {
      expect(html, contains('<html lang="ar" dir="rtl">'));
      expect(html, contains('<title>حاسبة تقسيم الراتب'));
      expect(html, contains('<h1>كيف أقسّم راتبي'));
      expect(
          html,
          contains(
              'rel="canonical" href="https://smartbudget.dgotix.com/salary-split/"'));
    });

    test('writes the name SmartBudget in Latin letters in what a reader sees',
        () {
      expect(visible, contains('SmartBudget'));
      expect(visible, isNot(contains('سمارت')));
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
      for (final String f in <String>['ui.js', 'split.js']) {
        expect(File('web/salary-split/$f').readAsStringSync(),
            isNot(anyOf(contains('fetch('), contains('XMLHttpRequest'))));
      }
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

    test('is listed in the sitemap and linked from the zakat page', () {
      expect(File('web/sitemap.xml').readAsStringSync(),
          contains('<loc>https://smartbudget.dgotix.com/salary-split/</loc>'));
      expect(File('web/zakat/index.html').readAsStringSync(),
          contains('href="/salary-split/"'));
    });

    test('says what the app adds: three months of spending, not a fixed rule',
        () {
      expect(visible, contains('آخر ثلاثة أشهر'));
      expect(SalarySplitEngine.historyMonths, 3);
    });
  });

  group("its sum is the app's sum", () {
    final bool haveNode = () {
      try {
        return Process.runSync('node', <String>['--version']).exitCode == 0;
      } catch (_) {
        return false;
      }
    }();

    // Incomes at random and at the edges (odd cents, tiny, huge).
    final Random rnd = Random(20261105);
    final List<String> incomes = <String>[
      for (int n = 0; n < 300; n++)
        (rnd.nextInt(2000000 * 100) / 100).toStringAsFixed(2),
      '0.01',
      '0.99',
      '1.00',
      '3.33',
      '1000000.01',
      '99999999.99',
      '100.05',
    ];

    test("300+ incomes split into the app's needs, wants and savings", () {
      final ProcessResult r = Process.runSync('node', <String>[
        '-e',
        '''
const s = require('./web/salary-split/split.js');
const incomes = ${jsonEncode(incomes)};
console.log(JSON.stringify(incomes.map((v) => {
  const r = s.splitSalary({income: v});
  return [Math.round(r.needs * 100), Math.round(r.wants * 100), Math.round(r.savings * 100)];
})));
''',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final List<dynamic> js = jsonDecode(r.stdout as String) as List<dynamic>;
      expect(js.length, incomes.length);

      for (int i = 0; i < incomes.length; i++) {
        final int minor = (double.parse(incomes[i]) * 100).round();
        final SalarySplit app = SalarySplitEngine.compute(
          income: Money(minor, 'USD'),
          transactions: const <Transaction>[],
          goals: const <Goal>[],
          year: 2026,
          month: 11,
        );
        final List<dynamic> page = js[i] as List<dynamic>;
        expect(
            page,
            <int>[
              app.needs.minorUnits,
              app.wants.minorUnits,
              app.savings.minorUnits,
            ],
            reason: 'income ${incomes[i]}');
        // The three always add up to the income.
        expect(
            app.needs.minorUnits +
                app.wants.minorUnits +
                app.savings.minorUnits,
            minor);
      }
    }, skip: haveNode ? false : 'node is not installed');
  });
}
