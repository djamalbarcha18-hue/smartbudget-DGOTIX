import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/share/domain/share_channels.dart';
import 'package:smartbudget/features/share/domain/share_highlight.dart';

void main() {
  const SharePayload p = SharePayload(
    text: 'جرّب SmartBudget 💡 now',
    link: 'https://example.com/app/',
    subject: 'Try it & see',
  );

  group('ShareLinks.uri', () {
    test('WhatsApp carries the text and the link in one message', () {
      final Uri u = ShareLinks.uri(ShareChannel.whatsapp, p)!;
      expect(u.host, 'wa.me');
      expect(u.queryParameters['text'], p.textWithLink);
    });

    test('Telegram and X keep the link separate from the text', () {
      final Uri tg = ShareLinks.uri(ShareChannel.telegram, p)!;
      expect(tg.queryParameters['url'], p.link);
      expect(tg.queryParameters['text'], p.text);
      final Uri x = ShareLinks.uri(ShareChannel.x, p)!;
      expect(x.path, '/intent/tweet');
      expect(x.queryParameters['url'], p.link);
    });

    test('Facebook and LinkedIn share the link; their caption is copied', () {
      expect(ShareLinks.uri(ShareChannel.facebook, p)!.queryParameters['u'],
          p.link);
      expect(ShareLinks.uri(ShareChannel.linkedin, p)!.queryParameters['url'],
          p.link);
      expect(ShareLinks.copiesCaption(ShareChannel.facebook), isTrue);
      expect(ShareLinks.copiesCaption(ShareChannel.linkedin), isTrue);
      expect(ShareLinks.copiesCaption(ShareChannel.whatsapp), isFalse);
    });

    test('email encodes spaces as %20 and escapes & in the subject', () {
      final String s = ShareLinks.uri(ShareChannel.email, p)!.toString();
      expect(s, startsWith('mailto:?subject=Try%20it%20%26%20see&body='));
      expect(s, isNot(contains('+')));
    });

    test('Instagram has no web share link (the app saves an image)', () {
      expect(ShareLinks.uri(ShareChannel.instagram, p), isNull);
      expect(ShareLinks.copiesCaption(ShareChannel.instagram), isTrue);
    });

    test('tone fits the channel', () {
      expect(ShareLinks.toneOf(ShareChannel.x), ShareTone.short);
      expect(ShareLinks.toneOf(ShareChannel.linkedin), ShareTone.professional);
      expect(ShareLinks.toneOf(ShareChannel.whatsapp), ShareTone.personal);
    });
  });

  group('ShareHighlight.pick', () {
    test('a completed goal leads, with other good news as extras', () {
      final ShareHighlight h = ShareHighlight.pick(
          hasData: true, healthScore: 88.4, savingsRate: 0.24, goalsCompleted: 2);
      expect(h.kind, HighlightKind.goals);
      expect(h.healthScore, 88);
      expect(h.healthStatus, HealthStatus.excellent);
      expect(h.savingsPct, 24);
      expect(h.extras, <HighlightKind>[HighlightKind.health, HighlightKind.savings]);
    });

    test('a good score leads when no goal is done yet', () {
      final ShareHighlight h = ShareHighlight.pick(
          hasData: true, healthScore: 72, savingsRate: 0.05, goalsCompleted: 0);
      expect(h.kind, HighlightKind.health);
      expect(h.savingsPct, isNull);
      expect(h.extras, isEmpty);
    });

    test('a weak score is never shown; savings can still lead', () {
      final ShareHighlight h = ShareHighlight.pick(
          hasData: true, healthScore: 41, savingsRate: 0.18, goalsCompleted: 0);
      expect(h.kind, HighlightKind.savings);
      expect(h.healthScore, isNull);
      expect(h.healthStatus, isNull);
    });

    test('nothing to boast yet → a positive "journey" card with no numbers', () {
      final ShareHighlight h = ShareHighlight.pick(
          hasData: true, healthScore: 30, savingsRate: -0.2, goalsCompleted: 0);
      expect(h.kind, HighlightKind.journey);
      expect(h.healthScore, isNull);
      expect(h.savingsPct, isNull);
      expect(h.extras, isEmpty);
    });

    test('no data at all → journey, even if the score defaults high', () {
      final ShareHighlight h = ShareHighlight.pick(
          hasData: false, healthScore: 90, savingsRate: 0.5, goalsCompleted: 0);
      expect(h.kind, HighlightKind.journey);
    });
  });
}
