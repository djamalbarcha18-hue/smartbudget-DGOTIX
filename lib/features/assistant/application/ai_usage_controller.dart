import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/assistant/data/ai_chat_service.dart';

String _monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Approximate provider prices in USD per 1,000,000 tokens, (input, output).
/// These are estimates for guidance only and may drift from the provider's
/// actual billing (free tiers can be $0). Update as prices change.
const Map<String, (double, double)> _pricingPerMTok = <String, (double, double)>{
  'gpt-4o-mini': (0.15, 0.60),
  'gpt-4o': (2.50, 10.0),
  'gpt-4.1-mini': (0.40, 1.60),
  'claude-3-5-haiku-latest': (0.80, 4.0),
  'claude-3-5-sonnet-latest': (3.0, 15.0),
  'gemini-2.0-flash': (0.10, 0.40),
  'gemini-2.0-flash-lite': (0.075, 0.30),
  'gemini-1.5-flash': (0.075, 0.30),
  'gemini-1.5-pro': (1.25, 5.0),
};

double _estCostUsd(String model, AiUsageStat s) {
  final (double, double)? p = _pricingPerMTok[model];
  if (p == null) return 0;
  return s.inputTokens / 1e6 * p.$1 + s.outputTokens / 1e6 * p.$2;
}

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
    required this.estCostUsd,
    required this.perModel,
  });

  final int requests;
  final int inputTokens;
  final int outputTokens;
  final double estCostUsd;
  final Map<String, AiUsageStat> perModel;

  int get totalTokens => inputTokens + outputTokens;
  bool get isEmpty => requests == 0;
}

/// On-device usage meter. Every successful AI request adds the token counts the
/// provider reported to the current month's bucket, so the user can see and
/// rationalize their consumption. This counts only requests made from this app
/// on this device — it is NOT the provider's account-wide billing (which a
/// personal key can't read from the browser).
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

  /// Records one request for [model] with the provider-reported [usage].
  void record(String model, AiUsage usage) {
    final String k = '${_monthKey(DateTime.now())}|$model';
    final AiUsageStat cur = state[k] ?? const AiUsageStat();
    state = <String, AiUsageStat>{
      ...state,
      k: cur.plus(
        req: 1,
        inTok: usage.inputTokens ?? 0,
        outTok: usage.outputTokens ?? 0,
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

/// An optional monthly cap the user sets to rationalize spending. Either field
/// may be null (no cap on that dimension).
class AiUsageLimit {
  const AiUsageLimit({this.maxRequests, this.maxCostUsd});
  final int? maxRequests;
  final double? maxCostUsd;

  bool get isSet => maxRequests != null || maxCostUsd != null;
}

/// Persisted monthly limit (per device). Null fields mean "no limit".
final aiUsageLimitProvider =
    NotifierProvider<AiUsageLimitController, AiUsageLimit>(
        AiUsageLimitController.new);

class AiUsageLimitController extends Notifier<AiUsageLimit> {
  static const String _reqKey = 'sb_ai_limit_req';
  static const String _costKey = 'sb_ai_limit_cost';

  @override
  AiUsageLimit build() {
    _load();
    return const AiUsageLimit();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final int? req = p.getInt(_reqKey);
      final double? cost = p.getDouble(_costKey);
      if (req != null || cost != null) {
        state = AiUsageLimit(maxRequests: req, maxCostUsd: cost);
      }
    } catch (_) {
      // Keep no-limit default.
    }
  }

  Future<void> save({int? maxRequests, double? maxCostUsd}) async {
    final int? req = (maxRequests != null && maxRequests > 0) ? maxRequests : null;
    final double? cost = (maxCostUsd != null && maxCostUsd > 0) ? maxCostUsd : null;
    state = AiUsageLimit(maxRequests: req, maxCostUsd: cost);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (req != null) {
        await p.setInt(_reqKey, req);
      } else {
        await p.remove(_reqKey);
      }
      if (cost != null) {
        await p.setDouble(_costKey, cost);
      } else {
        await p.remove(_costKey);
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> clear() => save();
}

/// How the current month's usage sits against the user's limit.
enum UsageLevel { ok, near, over }

class UsageAlert {
  const UsageAlert({required this.level, this.reqRatio, this.costRatio});
  final UsageLevel level;
  final double? reqRatio; // used / max requests (null = no request cap)
  final double? costRatio; // cost / max cost (null = no cost cap)
}

/// Evaluates this month's usage against the limit (near at >=80%, over at >=100%).
final aiUsageAlertProvider = Provider<UsageAlert>((ref) {
  final AiUsageLimit limit = ref.watch(aiUsageLimitProvider);
  if (!limit.isSet) return const UsageAlert(level: UsageLevel.ok);
  final AiUsageSummary u = ref.watch(aiUsageMonthProvider);

  final double? reqRatio = (limit.maxRequests != null && limit.maxRequests! > 0)
      ? u.requests / limit.maxRequests!
      : null;
  final double? costRatio = (limit.maxCostUsd != null && limit.maxCostUsd! > 0)
      ? u.estCostUsd / limit.maxCostUsd!
      : null;

  final double worst = <double>[
    if (reqRatio != null) reqRatio,
    if (costRatio != null) costRatio,
  ].fold<double>(0, (double m, double v) => v > m ? v : m);

  final UsageLevel level = worst >= 1.0
      ? UsageLevel.over
      : (worst >= 0.8 ? UsageLevel.near : UsageLevel.ok);
  return UsageAlert(level: level, reqRatio: reqRatio, costRatio: costRatio);
});

/// The current calendar month's usage, rolled up across models.
final aiUsageMonthProvider = Provider<AiUsageSummary>((ref) {
  final Map<String, AiUsageStat> map = ref.watch(aiUsageProvider);
  final String month = _monthKey(DateTime.now());
  int req = 0;
  int inTok = 0;
  int outTok = 0;
  double cost = 0;
  final Map<String, AiUsageStat> perModel = <String, AiUsageStat>{};
  for (final MapEntry<String, AiUsageStat> e in map.entries) {
    final List<String> parts = e.key.split('|');
    if (parts.length != 2 || parts[0] != month) continue;
    final String model = parts[1];
    final AiUsageStat s = e.value;
    req += s.requests;
    inTok += s.inputTokens;
    outTok += s.outputTokens;
    cost += _estCostUsd(model, s);
    perModel[model] = (perModel[model] ?? const AiUsageStat()).plus(
        req: s.requests, inTok: s.inputTokens, outTok: s.outputTokens);
  }
  return AiUsageSummary(
    requests: req,
    inputTokens: inTok,
    outputTokens: outTok,
    estCostUsd: cost,
    perModel: perModel,
  );
});
