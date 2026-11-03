/// The written analysis costs one of the account's assistant requests.
/// Exporting the same report twice must not cost two — and a cached sentence
/// about figures that have since moved would be worse than no sentence at
/// all. These two rules are what the cache is for.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/reports/data/report_insight_cache.dart';

String _key({
  String account = 'acct-1',
  String language = 'ar',
  String period = 'شهري — يناير · 2026',
  String brief = 'Income: 85000\nExpenses: 62900',
}) =>
    ReportInsightCache.keyFor(
      accountKey: account,
      language: language,
      periodLabel: period,
      brief: brief,
    );

void main() {
  const ReportInsightCache cache = ReportInsightCache();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('what is remembered', () {
    test('an analysis written once is read back without a request', () async {
      final String k = _key();
      expect(await cache.read(k), isNull);
      await cache.write(k, 'الإنفاق 74% من الدخل.');
      expect(await cache.read(k), 'الإنفاق 74% من الدخل.');
    });

    test('the same figures in the same language share one key', () {
      expect(_key(), _key());
    });
  });

  group('what makes it a different analysis', () {
    test('one changed figure', () {
      expect(_key(brief: 'Income: 85000\nExpenses: 62901'), isNot(_key()));
    });

    test('another language', () {
      expect(_key(language: 'fr'), isNot(_key()));
    });

    test('another period', () {
      expect(_key(period: 'شهري — فبراير · 2026'), isNot(_key()));
    });

    test('another account on the same device', () {
      expect(_key(account: 'acct-2'), isNot(_key()));
    });
  });

  group('how it behaves when things go wrong', () {
    test('a key never written is simply absent', () async {
      expect(await cache.read(_key(brief: 'never seen')), isNull);
    });

    test('a corrupt store reads as empty rather than throwing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ReportInsightCache.prefKey: 'not json at all',
      });
      expect(await cache.read(_key()), isNull);
      // And it recovers: writing replaces the broken value.
      await cache.write(_key(), 'fresh');
      expect(await cache.read(_key()), 'fresh');
    });

    test('an empty answer is not treated as an answer', () async {
      await cache.write(_key(), '   ');
      expect(await cache.read(_key()), isNull);
    });
  });

  test('it keeps the newest analyses and drops the oldest', () async {
    for (int i = 0; i < ReportInsightCache.keep + 5; i++) {
      await cache.write(_key(brief: 'brief $i'), 'text $i');
    }
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String stored = p.getString(ReportInsightCache.prefKey)!;
    // The store never grows without bound...
    expect(
        RegExp(r'"text":').allMatches(stored).length, ReportInsightCache.keep);
    // ...and the most recent is the one still there.
    expect(
        await cache.read(_key(brief: 'brief ${ReportInsightCache.keep + 4}')),
        'text ${ReportInsightCache.keep + 4}');
    expect(await cache.read(_key(brief: 'brief 0')), isNull);
  });
}
