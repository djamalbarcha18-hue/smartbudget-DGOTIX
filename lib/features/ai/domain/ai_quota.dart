/// What the server says about the user's DGOTIX AI allowance. The server is
/// the only counter (the device's own count can differ: another device, a
/// reinstall, a request the server refunded), so the app shows these numbers.
class AiQuotaInfo {
  const AiQuotaInfo({
    required this.limit,
    required this.used,
    required this.lifetime,
    this.resetsAt,
  });

  final int limit;
  final int used;

  /// A one-time allowance (the free plan), not a monthly one.
  final bool lifetime;

  /// When a monthly allowance starts over (UTC); null for a one-time one.
  final DateTime? resetsAt;

  int get remaining => (limit - used).clamp(0, limit);
  bool get spent => remaining == 0;
  double get usedFraction => limit <= 0 ? 1 : used / limit;

  /// Reads the gateway's `quota` object; null when it is missing or malformed.
  static AiQuotaInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? limit = json['limit'];
    final Object? used = json['used'];
    if (limit is! num || used is! num || limit <= 0 || used < 0) return null;
    final Object? reset = json['resetsAt'];
    return AiQuotaInfo(
      limit: limit.toInt(),
      used: used.toInt().clamp(0, limit.toInt()),
      lifetime: json['window'] == 'lifetime',
      resetsAt: reset is String ? DateTime.tryParse(reset) : null,
    );
  }
}
