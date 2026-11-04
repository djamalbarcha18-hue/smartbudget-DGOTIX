/// The founding offer: the first year of PRO yearly at a lower price, for a
/// limited time. The server says when it runs (billing-config); the app only
/// shows it, and the checkout charges it.
class FoundingOffer {
  const FoundingOffer({required this.yearlyUsd, required this.endsAt});

  /// The price of the first year, in USD (later years are the regular price).
  final double yearlyUsd;

  /// When the offer stops being sold.
  final DateTime endsAt;

  bool activeAt(DateTime now) => now.isBefore(endsAt);

  /// From billing-config's `offer`; null when absent or malformed.
  static FoundingOffer? fromJson(Object? j) {
    if (j is! Map) return null;
    final Object? price = j['yearlyUsd'];
    final DateTime? ends = DateTime.tryParse('${j['endsAt']}');
    if (price is! num || price <= 0 || ends == null) return null;
    return FoundingOffer(yearlyUsd: price.toDouble(), endsAt: ends);
  }
}
