import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/ai/domain/ai_registry.dart';
import 'package:smartbudget/features/assistant/data/ai_chat_service.dart';

String _monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// When the built-in prices in [ModelRegistry] were last reviewed. Shown to the
/// user so they know the estimate's basis (the app does NOT auto-sync provider
/// prices — there is no public pricing API a browser can read, and each
/// account's real price can differ by tier/discount/free-quota). Users can
/// override any price.
const String kPricesAsOf = '2026-09';

/// The built-in default price for a model (from the registry), or null.
(double, double)? defaultPriceOf(String model) {
  final AiModel? m = ModelRegistry.byId(model);
  return m == null ? null : (m.inputPer1M, m.outputPer1M);
}

/// The price actually used for a model: a user override if set, else the
/// built-in default, else (0, 0) — USD per 1,000,000 tokens (input, output).
(double, double) effectivePriceOf(
    String model, Map<String, (double, double)> overrides) {
  return overrides[model] ?? defaultPriceOf(model) ?? (0.0, 0.0);
}

double _estCostUsd(
    String model, AiUsageStat s, Map<String, (double, double)> overrides) {
  final (double, double) p = effectivePriceOf(model, overrides);
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

/// Per-model USD price overrides the user set (per 1,000,000 tokens). Persisted
/// on-device so a stale built-in table never forces a wrong estimate — the user
/// adjusts their own model's price to match their real provider pricing.
final aiPriceOverrideProvider =
    NotifierProvider<AiPriceOverrideController, Map<String, (double, double)>>(
        AiPriceOverrideController.new);

class AiPriceOverrideController
    extends Notifier<Map<String, (double, double)>> {
  static const String _key = 'sb_ai_prices';

  @override
  Map<String, (double, double)> build() {
    _load();
    return const <String, (double, double)>{};
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      state = m.map((String k, dynamic v) {
        final List<dynamic> pair = v as List<dynamic>;
        return MapEntry<String, (double, double)>(k,
            ((pair[0] as num).toDouble(), (pair[1] as num).toDouble()));
      });
    } catch (_) {
      // Keep defaults.
    }
  }

  /// Sets an override, or removes it when the values match the built-in default.
  void set(String model, double inputPerM, double outputPerM) {
    final (double, double)? def = defaultPriceOf(model);
    final Map<String, (double, double)> next =
        Map<String, (double, double)>.of(state);
    if (def != null && def.$1 == inputPerM && def.$2 == outputPerM) {
      next.remove(model);
    } else {
      next[model] = (inputPerM, outputPerM);
    }
    state = next;
    _persist();
  }

  void reset() {
    state = const <String, (double, double)>{};
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
            jsonEncode(state.map((String k, (double, double) v) =>
                MapEntry<String, dynamic>(
                    k, <double>[v.$1, v.$2]))));
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The current calendar month's usage, rolled up across models.
final aiUsageMonthProvider = Provider<AiUsageSummary>((ref) {
  final Map<String, AiUsageStat> map = ref.watch(aiUsageProvider);
  final Map<String, (double, double)> prices =
      ref.watch(aiPriceOverrideProvider);
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
    cost += _estCostUsd(model, s, prices);
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
