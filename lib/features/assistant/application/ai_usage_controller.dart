import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Accumulated usage for one (month, model) bucket.
class AiUsageStat {
  const AiUsageStat(
      {this.requests = 0, this.inputTokens = 0, this.outputTokens = 0});
  final int requests;
  final int inputTokens;
  final int outputTokens;

  int get totalTokens => inputTokens + outputTokens;

  AiUsageStat plus({int req = 0, int inTok = 0, int outTok = 0}) => AiUsageStat(
        requests: requests + req,
        inputTokens: inputTokens + inTok,
        outputTokens: outputTokens + outTok,
      );

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'r': requests, 'i': inputTokens, 'o': outputTokens};

  static AiUsageStat fromJson(Map<String, dynamic> j) => AiUsageStat(
        requests: (j['r'] as num?)?.toInt() ?? 0,
        inputTokens: (j['i'] as num?)?.toInt() ?? 0,
        outputTokens: (j['o'] as num?)?.toInt() ?? 0,
      );
}

/// A rolled-up summary for the current month, ready for display.
class AiUsageSummary {
  const AiUsageSummary({
    required this.requests,
    required this.inputTokens,
    required this.outputTokens,
  });

  final int requests;
  final int inputTokens;
  final int outputTokens;

  int get totalTokens => inputTokens + outputTokens;
  bool get isEmpty => requests == 0;
}

/// On-device usage meter. Every answered DGOTIX AI request is added to the
/// current month's bucket; it drives the quota display and nudges. The server
/// gateway remains the real enforcer of the plan's quota.
final aiUsageProvider =
    NotifierProvider<AiUsageController, Map<String, AiUsageStat>>(
        AiUsageController.new);

class AiUsageController extends Notifier<Map<String, AiUsageStat>> {
  static const String _key = 'sb_ai_usage';

  @override
  Map<String, AiUsageStat> build() {
    _load();
    return const <String, AiUsageStat>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      state = m.map((String k, dynamic v) => MapEntry<String, AiUsageStat>(
          k, AiUsageStat.fromJson((v as Map).cast<String, dynamic>())));
    } catch (_) {
      // Keep empty on corruption.
    }
  }

  /// Records one answered request (the local counter behind the quota
  /// nudges; the server remains the real enforcer).
  void record(String model, {int inputTokens = 0, int outputTokens = 0}) {
    final String k = '${_monthKey(DateTime.now())}|$model';
    final AiUsageStat cur = state[k] ?? const AiUsageStat();
    state = <String, AiUsageStat>{
      ...state,
      k: cur.plus(
        req: 1,
        inTok: inputTokens,
        outTok: outputTokens,
      ),
    };
    _persist();
  }

  void reset() {
    state = const <String, AiUsageStat>{};
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
            jsonEncode(state.map((String k, AiUsageStat v) =>
                MapEntry<String, dynamic>(k, v.toJson()))));
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The current calendar month's usage, rolled up across models.
final aiUsageMonthProvider = Provider<AiUsageSummary>((ref) {
  final Map<String, AiUsageStat> map = ref.watch(aiUsageProvider);
  final String month = _monthKey(DateTime.now());
  int req = 0;
  int inTok = 0;
  int outTok = 0;
  for (final MapEntry<String, AiUsageStat> e in map.entries) {
    final List<String> parts = e.key.split('|');
    if (parts.length != 2 || parts[0] != month) continue;
    final AiUsageStat s = e.value;
    req += s.requests;
    inTok += s.inputTokens;
    outTok += s.outputTokens;
  }
  return AiUsageSummary(
    requests: req,
    inputTokens: inTok,
    outputTokens: outTok,
  );
});
