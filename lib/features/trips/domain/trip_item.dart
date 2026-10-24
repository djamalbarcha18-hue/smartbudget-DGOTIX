import 'package:smartbudget/features/trips/domain/trip.dart';

/// What a trip's money goes on: the budget is split between these, and each
/// expense counts under one, read from its category.
enum TripItem {
  flights,
  stay,

  /// An organized trip's package from the agency (flights and stay).
  package,
  food,
  transport,
  activities,

  /// Internet and phone on the trip (a SIM or an eSIM plan).
  connectivity,
  gifts,
  emergency,

  /// Anything else (not planned; shown once something is spent on it).
  other,
}

/// The trip items, their categories and the suggested split.
abstract final class TripItems {
  /// The items an independent trip's budget is split between, in order.
  static const List<TripItem> planned = <TripItem>[
    TripItem.flights,
    TripItem.stay,
    TripItem.food,
    TripItem.transport,
    TripItem.activities,
    TripItem.connectivity,
    TripItem.gifts,
    TripItem.emergency,
  ];

  /// An organized trip's: the package instead of flights and stay.
  static const List<TripItem> plannedOrganized = <TripItem>[
    TripItem.package,
    TripItem.food,
    TripItem.transport,
    TripItem.activities,
    TripItem.connectivity,
    TripItem.gifts,
    TripItem.emergency,
  ];

  static List<TripItem> plannedFor(TripKind kind) =>
      kind == TripKind.organized ? plannedOrganized : planned;

  /// The item an expense counts under, from its category (on an organized
  /// trip, flights and stay are its package).
  static TripItem of(String category,
          [TripKind kind = TripKind.independent]) =>
      switch (category) {
        'السفر' || 'السكن' when kind == TripKind.organized =>
          TripItem.package,
        'السفر' => TripItem.flights,
        'السكن' => TripItem.stay,
        'المطاعم' || 'الطعام' => TripItem.food,
        'النقل' || 'الوقود' => TripItem.transport,
        'الترفيه' || 'الرياضة واللياقة' => TripItem.activities,
        'التسوق' || 'الملابس' => TripItem.gifts,
        'الطوارئ' || 'الصحة' || 'التأمين' => TripItem.emergency,
        'الاتصالات والإنترنت' => TripItem.connectivity,
        _ => TripItem.other,
      };

  /// The category an expense picked as [item] is saved under, so it still
  /// counts in the month's budget and reports.
  static String categoryOf(TripItem item) => switch (item) {
        TripItem.flights => 'السفر',
        TripItem.stay => 'السكن',
        TripItem.package => 'السفر',
        TripItem.connectivity => 'الاتصالات والإنترنت',
        TripItem.food => 'المطاعم',
        TripItem.transport => 'النقل',
        TripItem.activities => 'الترفيه',
        TripItem.gifts => 'التسوق',
        TripItem.emergency => 'الطوارئ',
        TripItem.other => 'أخرى',
      };

  /// The suggested split in percent (adds up to 100): by the trip's kind
  /// and level, then its length — a long stay needs more for the hotel and
  /// meals and less, in share, for the flights; a short one the other way
  /// round. Internet and phone take a small share (a SIM or an eSIM).
  static Map<TripItem, int> suggested(TripLevel? level, int days,
      [TripKind kind = TripKind.independent]) {
    final List<TripItem> items = plannedFor(kind);
    final List<int> p;
    if (kind == TripKind.organized) {
      p = switch (level) {
        // Package, food, transport, activities, internet, gifts, emergency.
        TripLevel.economy => <int>[62, 12, 5, 5, 3, 5, 8],
        TripLevel.luxury => <int>[70, 8, 3, 8, 2, 6, 3],
        TripLevel.standard || null => <int>[65, 10, 4, 7, 3, 6, 5],
      };
      if (days >= 10) {
        p[0] -= 4; // more days on the spot: more meals around the package
        p[1] += 4;
      }
    } else {
      p = switch (level) {
        // Flights, stay, food, transport, activities, internet, gifts,
        // emergency.
        TripLevel.economy => <int>[32, 20, 17, 11, 6, 3, 5, 6],
        TripLevel.luxury => <int>[28, 32, 15, 6, 8, 2, 6, 3],
        TripLevel.standard || null => <int>[30, 25, 16, 9, 7, 3, 5, 5],
      };
      if (days >= 10) {
        p[0] -= 6;
        p[1] += 3;
        p[2] += 3;
      } else if (days <= 3) {
        p[0] += 4;
        p[1] -= 2;
        p[2] -= 2;
      }
    }
    return <TripItem, int>{
      for (int i = 0; i < items.length; i++) items[i]: p[i],
    };
  }

  /// The trip's split: the user's own, else the suggested one.
  static Map<TripItem, int> splitOf(Trip t) =>
      t.split ??
      suggested(t.level, t.end.difference(t.start).inDays + 1, t.kind);

  /// [split] with [item] set to [percent]; the others share what is left in
  /// their current proportions (evenly when they are all at zero), so the
  /// total stays 100.
  static Map<TripItem, int> withShare(
      Map<TripItem, int> split, TripItem item, int percent) {
    final int value = percent.clamp(0, 100);
    final List<TripItem> items = split.keys.toList();
    final List<TripItem> others =
        items.where((TripItem i) => i != item).toList();
    final int before =
        others.fold<int>(0, (int a, TripItem i) => a + (split[i] ?? 0));
    final List<double> weights = <double>[
      for (final TripItem i in others)
        before == 0 ? 1 : (split[i] ?? 0).toDouble(),
    ];
    final List<int> parts = shares(100 - value, weights);
    return <TripItem, int>{
      for (final TripItem i in items)
        i: i == item ? value : parts[others.indexOf(i)],
    };
  }

  /// [total] in whole parts by [weights], adding up to [total] exactly
  /// (largest remainders first).
  static List<int> shares(int total, List<double> weights) {
    final double sum = weights.fold<double>(0, (double a, double w) => a + w);
    if (sum <= 0 || weights.isEmpty) {
      return List<int>.filled(weights.length, 0);
    }
    final List<double> exact = <double>[
      for (final double w in weights) total * w / sum,
    ];
    final List<int> out = <int>[for (final double e in exact) e.floor()];
    int left = total - out.fold<int>(0, (int a, int v) => a + v);
    final List<int> order = List<int>.generate(weights.length, (int i) => i)
      ..sort((int a, int b) =>
          (exact[b] - out[b]).compareTo(exact[a] - out[a]));
    for (final int i in order) {
      if (left <= 0) break;
      out[i]++;
      left--;
    }
    return out;
  }

  /// A split read back from storage, or null unless it covers the items of
  /// a trip of [kind] and adds up to 100.
  static Map<TripItem, int>? parse(Object? json,
      [TripKind kind = TripKind.independent]) {
    if (json is! Map) return null;
    final Map<TripItem, int> out = <TripItem, int>{};
    for (final TripItem i in plannedFor(kind)) {
      final Object? v = json[i.name];
      if (v is! num || v < 0) return null;
      out[i] = v.toInt();
    }
    final int sum = out.values.fold<int>(0, (int a, int v) => a + v);
    return sum == 100 ? out : null;
  }
}
