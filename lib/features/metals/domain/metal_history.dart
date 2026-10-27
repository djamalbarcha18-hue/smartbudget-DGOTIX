/// What the user's metals were worth on one day, in one currency.
class MetalPoint {
  const MetalPoint({
    required this.day,
    required this.minor,
    required this.currency,
    this.paid,
  });

  /// The day, at midnight.
  final DateTime day;
  final int minor;
  final String currency;

  /// What had been paid for the metals held that day, when every piece had
  /// a cost (else null): the line that the value is compared with.
  final int? paid;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'd': '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        'v': minor,
        'c': currency,
        if (paid != null) 'p': paid,
      };

  static MetalPoint? fromJson(Object? j) {
    if (j is! Map) return null;
    final DateTime? d = DateTime.tryParse('${j['d']}');
    final Object? v = j['v'];
    final Object? c = j['c'];
    final Object? p = j['p'];
    if (d == null || v is! int || c is! String || c.isEmpty) return null;
    return MetalPoint(
        day: DateTime(d.year, d.month, d.day),
        minor: v,
        currency: c,
        paid: p is int ? p : null);
  }
}

/// The value of the user's metals day by day, as seen in the app: there is
/// no free history of prices, so the line starts on the first day the value
/// was known and gains a point each day the app is opened.
abstract final class MetalHistory {
  /// About two years of daily points.
  static const int keep = 750;

  /// [points] with today's value set (one point per day, the latest wins),
  /// oldest first.
  static List<MetalPoint> record(List<MetalPoint> points, MetalPoint today) {
    final List<MetalPoint> out = <MetalPoint>[
      for (final MetalPoint p in points)
        if (p.day != today.day) p,
      today,
    ]..sort((MetalPoint a, MetalPoint b) => a.day.compareTo(b.day));
    return out.length > keep ? out.sublist(out.length - keep) : out;
  }

  /// The points in [currency] within the last [days] days before [now]
  /// (all of them when [days] is null).
  static List<MetalPoint> series(
      List<MetalPoint> points, String currency, DateTime now,
      {int? days}) {
    final DateTime from = days == null
        ? DateTime(0)
        : DateTime(now.year, now.month, now.day - days);
    return <MetalPoint>[
      for (final MetalPoint p in points)
        if (p.currency == currency && !p.day.isBefore(from)) p,
    ];
  }
}
