import 'package:smartbudget/features/trips/domain/trip.dart';

/// What a trip's money goes on: the budget is split between these, and each
/// expense counts under one, read from its category.
enum TripItem {
  flights,
  stay,
  food,
  transport,
  activities,
  gifts,
  emergency,

  /// Anything else (not planned; shown once something is spent on it).
  other,
}

/// The trip items, their categories and the suggested split.
abstract final class TripItems {
  /// The items the budget is split between, in this order.
  static const List<TripItem> planned = <TripItem>[
    TripItem.flights,
    TripItem.stay,
    TripItem.food,
    TripItem.transport,
    TripItem.activities,
    TripItem.gifts,
    TripItem.emergency,
  ];

  /// The item an expense counts under, from its category.
  static TripItem of(String category) => switch (category) {
        'السفر' => TripItem.flights,
        'السكن' => TripItem.stay,
        'المطاعم' || 'الطعام' => TripItem.food,
        'النقل' || 'الوقود' => TripItem.transport,
        'الترفيه' || 'الرياضة واللياقة' => TripItem.activities,
        'التسوق' || 'الملابس' => TripItem.gifts,
        'الطوارئ' || 'الصحة' || 'التأمين' => TripItem.emergency,
        _ => TripItem.other,
      };

  /// The category an expense picked as [item] is saved under, so it still
  /// counts in the month's budget and reports.
  static String categoryOf(TripItem item) => switch (item) {
        TripItem.flights => 'السفر',
        TripItem.stay => 'السكن',
        TripItem.food => 'المطاعم',
        TripItem.transport => 'النقل',
        TripItem.activities => 'الترفيه',
        TripItem.gifts => 'التسوق',
        TripItem.emergency => 'الطوارئ',
        TripItem.other => 'أخرى',
      };

  /// The suggested split in percent (adds up to 100): by the trip's level,
  /// then its length — a long stay needs more for the hotel and meals and
  /// less, in share, for the flights; a short one the other way round.
  static Map<TripItem, int> suggested(TripLevel? level, int days) {
    final List<int> p = switch (level) {
      // Flights, stay, food, transport, activities, gifts, emergency.
      TripLevel.economy => <int>[32, 20, 18, 12, 6, 5, 7],
      TripLevel.luxury => <int>[28, 32, 16, 7, 8, 6, 3],
      TripLevel.standard || null => <int>[30, 25, 17, 10, 8, 5, 5],
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
    return <TripItem, int>{
      for (int i = 0; i < planned.length; i++) planned[i]: p[i],
    };
  }

  /// The trip's split: the user's own, else the suggested one.
  static Map<TripItem, int> splitOf(Trip t) =>
      t.split ?? suggested(t.level, t.end.difference(t.start).inDays + 1);

  /// [split] with [item] set to [percent]; the others share what is left in
  /// their current proportions (evenly when they are all at zero), so the
  /// total stays 100.
  static Map<TripItem, int> withShare(
      Map<TripItem, int> split, TripItem item, int percent) {
    final int value = percent.clamp(0, 100);
    final List<TripItem> others =
        planned.where((TripItem i) => i != item).toList();
    final int before =
        others.fold<int>(0, (int a, TripItem i) => a + (split[i] ?? 0));
    final List<double> weights = <double>[
      for (final TripItem i in others)
        before == 0 ? 1 : (split[i] ?? 0).toDouble(),
    ];
    final List<int> parts = shares(100 - value, weights);
    return <TripItem, int>{
      for (final TripItem i in planned)
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

  /// A split read back from storage, or null unless it covers the planned
  /// items and adds up to 100.
  static Map<TripItem, int>? parse(Object? json) {
    if (json is! Map) return null;
    final Map<TripItem, int> out = <TripItem, int>{};
    for (final TripItem i in planned) {
      final Object? v = json[i.name];
      if (v is! num || v < 0) return null;
      out[i] = v.toInt();
    }
    final int sum = out.values.fold<int>(0, (int a, int v) => a + v);
    return sum == 100 ? out : null;
  }
}
