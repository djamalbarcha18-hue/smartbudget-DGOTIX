import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/guide/domain/guide_content.dart';

void main() {
  test('English and Arabic guides cover the same features in the same order',
      () {
    final List<GuideTopic> en = GuideContent.topics(ar: false);
    final List<GuideTopic> ar = GuideContent.topics(ar: true);
    expect(ar.map((GuideTopic t) => t.route).toList(),
        en.map((GuideTopic t) => t.route).toList());
    for (int i = 0; i < en.length; i++) {
      expect(ar[i].steps.length, en[i].steps.length,
          reason: 'step count differs for ${en[i].route}');
    }
  });

  test('every topic has a title, summary and at least one step', () {
    for (final bool ar in <bool>[false, true]) {
      for (final GuideTopic t in GuideContent.topics(ar: ar)) {
        expect(t.title, isNotEmpty);
        expect(t.summary, isNotEmpty);
        expect(t.steps, isNotEmpty);
        expect(t.route, startsWith('/'));
      }
    }
  });

  test('getting-started steps match between languages', () {
    expect(GuideContent.gettingStarted(ar: true).length,
        GuideContent.gettingStarted(ar: false).length);
  });
}
