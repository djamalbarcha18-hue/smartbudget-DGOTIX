import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/guide/domain/guide_content.dart';

void main() {
  test('every language covers the same features in the same order', () {
    final List<GuideTopic> en = GuideContent.topics(lang: AppLang.en);
    for (final AppLang lang in <AppLang>[AppLang.ar, AppLang.fr]) {
      final List<GuideTopic> other = GuideContent.topics(lang: lang);
      expect(other.map((GuideTopic t) => t.route).toList(),
          en.map((GuideTopic t) => t.route).toList(),
          reason: lang.name);
      for (int i = 0; i < en.length; i++) {
        expect(other[i].steps.length, en[i].steps.length,
            reason: 'step count differs for ${en[i].route} (${lang.name})');
      }
    }
  });

  test('French is its own text, not the English one', () {
    expect(GuideContent.topics(lang: AppLang.fr).first.title,
        isNot(GuideContent.topics(lang: AppLang.en).first.title));
  });

  test('every topic has a title, summary and at least one step', () {
    for (final AppLang lang in AppLang.values) {
      for (final GuideTopic t in GuideContent.topics(lang: lang)) {
        expect(t.title, isNotEmpty);
        expect(t.summary, isNotEmpty);
        expect(t.steps, isNotEmpty);
        expect(t.route, startsWith('/'));
      }
    }
  });

  test('getting-started steps match between languages', () {
    for (final AppLang lang in AppLang.values) {
      expect(GuideContent.gettingStarted(lang: lang).length,
          GuideContent.gettingStarted(lang: AppLang.en).length);
    }
  });
}
