import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/assistant/data/ai_chat_service.dart';
import 'package:smartbudget/features/financial_health/application/health_controller.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// The AI chat service (BYOK, direct-to-provider from the browser).
final aiChatServiceProvider =
    Provider<AiChatService>((ref) => const AiChatService());

/// A compact, REAL-DATA snapshot of the user's finances, handed to the model as
/// context so answers are personalized. Contains only figures the app already
/// computed — never fabricated. Kept short to stay cheap on the user's key.
final aiContextProvider = Provider<String>((ref) {
  final FinanceSummary sum = ref.watch(financeSummaryProvider);
  final String currency = ref.watch(baseCurrencyProvider);
  final HealthReport report = ref.watch(healthReportProvider);

  final StringBuffer b = StringBuffer();
  b.writeln('Base currency: $currency.');
  if (sum.count > 0) {
    b.writeln('This year — income: ${MoneyFormatter.format(sum.income)}, '
        'expenses: ${MoneyFormatter.format(sum.expense)}, '
        'net: ${MoneyFormatter.format(sum.net)}, '
        'savings rate: ${MoneyFormatter.percent(sum.savingsRate)}.');
  } else {
    b.writeln('No transactions recorded yet.');
  }
  if (report.hasData) {
    b.writeln('Financial health score: ${report.score.round()}/100 '
        '(data confidence ${report.confidence.round()}%).');
  }
  return b.toString().trim();
});

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

/// The saved conversation, persisted on-device so it survives reloads. Capped to
/// the most recent [_maxStored] turns to stay small.
final chatMessagesProvider =
    NotifierProvider<ChatMessagesController, List<ChatMessage>>(
        ChatMessagesController.new);

class ChatMessagesController extends Notifier<List<ChatMessage>> {
  static const String _key = 'sb_ai_chat';
  static const int _maxStored = 40;

  @override
  List<ChatMessage> build() {
    _load();
    return const <ChatMessage>[];
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((dynamic e) =>
              ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      // Keep empty on any corruption.
    }
  }

  void add(ChatMessage m) {
    final List<ChatMessage> next = <ChatMessage>[...state, m];
    state = next.length > _maxStored
        ? next.sublist(next.length - _maxStored)
        : next;
    _persist();
  }

  void clear() {
    state = const <ChatMessage>[];
    _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (state.isEmpty) {
        await p.remove(_key);
      } else {
        await p.setString(
            _key,
            jsonEncode(state
                .map((ChatMessage m) => m.toJson())
                .toList(growable: false)));
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}
