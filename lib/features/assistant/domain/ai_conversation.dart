/// Pure conversation helpers for DGOTIX AI (no Flutter, no IO): the message
/// model, the single system prompt shared by every backend, and how much of
/// the conversation is sent back as memory.
library;

/// One turn in the Ask-DGOTIX-AI conversation.
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'u': fromUser, 't': text};

  static ChatMessage fromJson(Map<String, dynamic> j) =>
      ChatMessage(fromUser: j['u'] == true, text: (j['t'] ?? '').toString());
}

abstract final class AiPrompts {
  /// The one DGOTIX AI system prompt (the gateway keeps an identical copy in
  /// supabase/functions/_shared/ai/gateway.ts).
  static String system(String context) =>
      'You are DGOTIX AI, a concise, practical personal-finance assistant '
      'inside the SmartBudget app. Use the user\'s real financial context '
      'below when it helps, and refer to the actual figures. Never invent '
      'exact figures that are not provided; if something is missing, say so '
      'and suggest where in the app to add it. Prefer halal-friendly guidance '
      '(no interest-based products). Reply in the same language as the '
      'user\'s latest message (Arabic or English). Keep answers short: a '
      'sentence or two, then at most 5 bullet points using "- ", with **bold** '
      'for key numbers. Use Latin digits (0-9).\n\n'
      'User financial context:\n$context';
}

abstract final class AiConversation {
  /// How many earlier messages are sent as memory with a new question.
  static const int maxTurns = 6;

  /// Each remembered message is capped so memory stays cheap.
  static const int maxCharsPerTurn = 700;

  /// The memory to send with the question the user just asked: the last
  /// [maxTurns] messages before it, oldest first, starting with a user turn
  /// and alternating roles (consecutive same-role turns are merged), each
  /// trimmed to [maxCharsPerTurn].
  ///
  /// [all] is the saved conversation INCLUDING the new question as its last
  /// element (it is excluded from the memory).
  static List<ChatMessage> history(List<ChatMessage> all) {
    if (all.length <= 1) return const <ChatMessage>[];
    final List<ChatMessage> before = all.sublist(0, all.length - 1);
    final List<ChatMessage> recent = before.length > maxTurns
        ? before.sublist(before.length - maxTurns)
        : before;

    final List<ChatMessage> out = <ChatMessage>[];
    for (final ChatMessage m in recent) {
      final String t = m.text.trim();
      if (t.isEmpty) continue;
      if (out.isEmpty && !m.fromUser) continue; // must start with the user
      if (out.isNotEmpty && out.last.fromUser == m.fromUser) {
        out[out.length - 1] = ChatMessage(
            fromUser: m.fromUser, text: _cap('${out.last.text}\n$t'));
      } else {
        out.add(ChatMessage(fromUser: m.fromUser, text: _cap(t)));
      }
    }
    // The new question is a user turn, so memory must end with the assistant.
    while (out.isNotEmpty && out.last.fromUser) {
      out.removeLast();
    }
    return out;
  }

  static String _cap(String s) => s.length <= maxCharsPerTurn
      ? s
      : '${s.substring(0, maxCharsPerTurn)}…';
}
