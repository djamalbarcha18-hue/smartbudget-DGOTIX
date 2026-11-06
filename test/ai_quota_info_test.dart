import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/ai/domain/ai_quota.dart';

void main() {
  group('the allowance as the server reports it', () {
    test('reads the gateway\'s quota object', () {
      final AiQuotaInfo q = AiQuotaInfo.fromJson(<String, dynamic>{
        'limit': 80,
        'used': 30,
        'remaining': 50,
        'window': 'monthly',
        'resetsAt': '2026-12-01T00:00:00.000Z',
      })!;
      expect(q.limit, 80);
      expect(q.used, 30);
      expect(q.remaining, 50);
      expect(q.lifetime, isFalse);
      expect(q.spent, isFalse);
      expect(q.resetsAt, DateTime.utc(2026, 12, 1));
      expect(q.usedFraction, closeTo(0.375, 1e-9));
    });

    test('a one-time allowance has no reset date', () {
      final AiQuotaInfo q = AiQuotaInfo.fromJson(<String, dynamic>{
        'limit': 5,
        'used': 5,
        'window': 'lifetime',
        'resetsAt': null,
      })!;
      expect(q.lifetime, isTrue);
      expect(q.resetsAt, isNull);
      expect(q.spent, isTrue);
      expect(q.remaining, 0);
    });

    test('never negative, never above the limit', () {
      final AiQuotaInfo q = AiQuotaInfo.fromJson(
          <String, dynamic>{'limit': 80, 'used': 95, 'window': 'monthly'})!;
      expect(q.used, 80);
      expect(q.remaining, 0);
    });

    test('anything malformed is ignored, not trusted', () {
      expect(AiQuotaInfo.fromJson(null), isNull);
      expect(AiQuotaInfo.fromJson('x'), isNull);
      expect(AiQuotaInfo.fromJson(<String, dynamic>{'limit': 'a', 'used': 1}),
          isNull);
      expect(AiQuotaInfo.fromJson(<String, dynamic>{'limit': 0, 'used': 0}),
          isNull);
      expect(AiQuotaInfo.fromJson(<String, dynamic>{'limit': 80, 'used': -3}),
          isNull);
    });
  });
}
