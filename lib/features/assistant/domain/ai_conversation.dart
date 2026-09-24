/// Pure conversation helpers for DGOTIX AI (no Flutter, no IO): the message
/// model and how much of the conversation is sent back as memory. The system
/// prompt lives on the server (supabase/functions/_shared/ai/gateway.ts).
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
