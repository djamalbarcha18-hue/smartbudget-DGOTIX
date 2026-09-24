import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/text/markdown_lite.dart';
import 'package:smartbudget/features/assistant/domain/ai_conversation.dart';
import 'package:smartbudget/features/assistant/domain/ai_snapshot.dart';

ChatMessage u(String t) => ChatMessage(fromUser: true, text: t);
ChatMessage a(String t) => ChatMessage(fromUser: false, text: t);

void main() {
  group('conversation memory', () {
    test('first question has no memory', () {
      expect(AiConversation.history(<ChatMessage>[u('hi')]), isEmpty);
    });

    test('sends the recent turns before the new question, oldest first', () {
      final List<ChatMessage> h = AiConversation.history(<ChatMessage>[
        u('q1'), a('a1'), u('q2'), a('a2'), u('q3'),
      ]);
      expect(h.map((ChatMessage m) => m.text), <String>['q1', 'a1', 'q2', 'a2']);
    });

    test('keeps at most maxTurns and always starts with the user', () {
      final List<ChatMessage> all = <ChatMessage>[
        for (int i = 0; i < 10; i++) ...<ChatMessage>[u('q$i'), a('a$i')],
        u('new'),
      ];
      final List<ChatMessage> h = AiConversation.history(all);
      expect(h.length, lessThanOrEqualTo(AiConversation.maxTurns));
      expect(h.first.fromUser, isTrue);
      expect(h.last.fromUser, isFalse);
      expect(h.last.text, 'a9');
    });

    test('merges consecutive same-role turns and caps long ones', () {
      final List<ChatMessage> h = AiConversation.history(<ChatMessage>[
        u('a'), u('b'), a('x' * 2000), u('now'),
      ]);
      expect(h.first.text, 'a\nb');
      expect(h.last.text.length, AiConversation.maxCharsPerTurn + 1);
      // Roles alternate.
      for (int i = 1; i < h.length; i++) {
        expect(h[i].fromUser, isNot(h[i - 1].fromUser));
      }
    });

    test('a failed question (no answer yet) is not sent twice', () {
      final List<ChatMessage> h = AiConversation.history(<ChatMessage>[
        u('q1'), a('a1'), u('unanswered'), u('retry'),
      ]);
      expect(h.map((ChatMessage m) => m.text), <String>['q1', 'a1']);
    });
  });

  group('system prompt', () {
    test('the server gateway carries the DGOTIX AI rules', () {
      final String ts =
          File('supabase/functions/_shared/ai/gateway.ts').readAsStringSync();
      final int start = ts.indexOf('const SYSTEM =');
      expect(start, greaterThanOrEqualTo(0));
      // The declaration ends at the closing quote followed by ';'.
      final String decl = ts.substring(start, ts.indexOf('";', start) + 1);
      final String server = RegExp(r'"((?:[^"\\]|\\.)*)"')
          .allMatches(decl)
          .map((RegExpMatch m) => m.group(1)!.replaceAll(r'\"', '"'))
          .join();
      expect(server, contains('DGOTIX AI'));
      expect(server, contains('Never invent'));
      expect(server, contains('halal'));
      expect(server, contains('Latin digits'));
    });
  });

  group('financial snapshot', () {
    test('no data says so and nothing else', () {
      final String s = AiSnapshot.build(const AiSnapshotInput(
          currency: 'USD', today: '2026-09-24', hasData: false));
      expect(s, contains('No transactions recorded yet.'));
      expect(s, isNot(contains('Budget')));
    });

    test('includes the month, categories, budget and health lines', () {
      final String s = AiSnapshot.build(const AiSnapshotInput(
        currency: 'USD',
        today: '2026-09-24',
        hasData: true,
        monthLabel: '2026-09',
        monthIncome: r'$ 4,430.00',
        monthExpense: r'$ 2,047.00',
        monthNet: r'$ 2,383.00',
        topCategories: <AiCategoryLine>[
          AiCategoryLine('السكن', r'$ 855.00', 0.42),
        ],
        budgetPlanned: r'$ 2,131.50',
        budgetSpent: r'$ 2,047.00',
        budgetUsed: 0.96,
        healthScore: 91,
        healthStatus: 'excellent',
        healthConfidence: 79,
      ));
      expect(s, contains(r'This month (2026-09): income $ 4,430.00'));
      expect(s, contains(r'السكن $ 855.00 (42%)'));
      expect(s, contains('(96% used)'));
      expect(s, contains('Financial health: 91/100 (excellent)'));
      expect(s, contains('Zakat: not due'));
    });

    test('an unset budget is stated, never guessed', () {
      final String s = AiSnapshot.build(const AiSnapshotInput(
          currency: 'USD', today: '2026-09-24', hasData: true));
      expect(s, contains('Budget this month: not set.'));
    });
  });

  group('markdown for answers', () {
    test('bullets, numbers, headings and bold', () {
      final List<MdBlock> b = MarkdownLite.parse(
          '## Plan\nCut **food** costs:\n- cook at home\n* compare prices\n2) review subscriptions');
      expect(b.map((MdBlock x) => x.type), <MdBlockType>[
        MdBlockType.heading,
        MdBlockType.paragraph,
        MdBlockType.bullet,
        MdBlockType.bullet,
        MdBlockType.numbered,
      ]);
      expect(b[1].spans.where((MdSpan s) => s.bold).single.text, 'food');
      expect(b[4].marker, '2.');
      expect(b[4].plainText, 'review subscriptions');
    });

    test('never leaves raw markers on screen', () {
      final List<MdBlock> b = MarkdownLite.parse('Use `budget` and __save__');
      expect(b.single.plainText, 'Use budget and save');
    });

    test('figures keep their order inside Arabic text', () {
      final MdBlock b = MarkdownLite.parse('انقل 10% أي \$ 200').single;
      final String shown = b.spans.map((MdSpan s) => s.text).join();
      expect(shown, contains('\u206610%\u2069'));
      expect(shown, contains('\u2066\$ 200\u2069'));
      expect(b.plainText, 'انقل 10% أي \$ 200');
    });

    test('reading direction follows each paragraph', () {
      expect(MarkdownLite.isRtl('خفّض المصروفات 10%'), isTrue);
      expect(MarkdownLite.isRtl('10% of income'), isFalse);
    });
  });
}
