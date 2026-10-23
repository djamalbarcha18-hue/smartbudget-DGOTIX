import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';

/// A trip: where to, when, and optionally how much it should cost. Expenses
/// made for it carry its id ([Transaction.tripId]).
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.start,
    required this.end,
    required this.createdAt,
    this.plannedBudget,
    this.goalId,
    this.travelers = 1,
  });

  final String id;
  final String name;

  /// Where to, as text: a catalog name or anything the user typed.
  final String destination;

  /// First and last day (dates only).
  final DateTime start;
  final DateTime end;

  final Money? plannedBudget;
  final DateTime createdAt;

  /// The savings goal set up for it, if any (SmartTrip phase 2).
  final String? goalId;

  /// How many people the trip's budget and expenses are for (at least 1).
  final int travelers;

  Trip copyWith({String? goalId, bool clearGoal = false}) => Trip(
        id: id,
        name: name,
        destination: destination,
        start: start,
        end: end,
        plannedBudget: plannedBudget,
        createdAt: createdAt,
        goalId: clearGoal ? null : goalId ?? this.goalId,
        travelers: travelers,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'destination': destination,
        'start': _ymd(start),
        'end': _ymd(end),
        if (plannedBudget != null) 'budgetMinor': plannedBudget!.minorUnits,
        if (plannedBudget != null) 'currency': plannedBudget!.currencyCode,
        'createdAt': createdAt.toIso8601String(),
        if (goalId != null) 'goalId': goalId,
        if (travelers > 1) 'travelers': travelers,
      };

  factory Trip.fromJson(Map<String, dynamic> j) {
    final DateTime start = _parseDay(j['start']);
    final DateTime end = _parseDay(j['end']);
    return Trip(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      destination: (j['destination'] as String?) ?? '',
      start: start,
      end: end.isBefore(start) ? start : end,
      plannedBudget: j['budgetMinor'] == null
          ? null
          : Money((j['budgetMinor'] as num).toInt(),
              (j['currency'] as String?) ?? 'USD'),
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
          DateTime(2026),
      goalId: j['goalId'] as String?,
      travelers: ((j['travelers'] as num?)?.toInt() ?? 1).clamp(1, 99),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(Object? v) {
    final DateTime d =
        DateTime.tryParse((v as String?) ?? '') ?? DateTime(2026);
    return DateTime(d.year, d.month, d.day);
  }
}

enum TripStatus { upcoming, active, ended }

abstract final class TripMath {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static TripStatus status(Trip t, DateTime now) {
    final DateTime today = _day(now);
    if (today.isBefore(t.start)) return TripStatus.upcoming;
    if (today.isAfter(t.end)) return TripStatus.ended;
    return TripStatus.active;
  }

  /// Days until it starts (0 on the first day).
  static int daysUntil(Trip t, DateTime now) =>
      t.start.difference(_day(now)).inDays;

  static bool covers(Trip t, DateTime date) {
    final DateTime d = _day(date);
    return !d.isBefore(t.start) && !d.isAfter(t.end);
  }

  /// The trip under way on [date] (the latest to start, if several).
  static Trip? activeOn(List<Trip> trips, DateTime date) {
    Trip? best;
    for (final Trip t in trips) {
      if (covers(t, date) && (best == null || t.start.isAfter(best.start))) {
        best = t;
      }
    }
    return best;
  }

  /// Under way and coming up, soonest first.
  static List<Trip> current(List<Trip> trips, DateTime now) =>
      trips.where((Trip t) => status(t, now) != TripStatus.ended).toList()
        ..sort((Trip a, Trip b) => a.start.compareTo(b.start));

  /// Over, most recent first.
  static List<Trip> past(List<Trip> trips, DateTime now) =>
      trips.where((Trip t) => status(t, now) == TripStatus.ended).toList()
        ..sort((Trip a, Trip b) => b.end.compareTo(a.end));

  static List<Transaction> expensesOf(Trip t, List<Transaction> txns) =>
      txns.where((Transaction x) => x.isExpense && x.tripId == t.id).toList();

  /// What its expenses add up to in [currency] (amounts with no value there
  /// are left out, as in every other total).
  static Money spent(Trip t, List<Transaction> txns, String currency) {
    int minor = 0;
    for (final Transaction x in expensesOf(t, txns)) {
      minor += x.inCurrency(currency)?.amount.minorUnits ?? 0;
    }
    return Money(minor, currency);
  }

  /// Where the user went or is going, most recent trip first, each place
  /// once (a catalog place in any language counts as one).
  static List<String> pastDestinations(List<Trip> trips,
      {DestinationCatalog? catalog, int max = 5}) {
    final List<Trip> byRecent = List<Trip>.of(trips)
      ..sort((Trip a, Trip b) => b.createdAt.compareTo(a.createdAt));
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final Trip t in byRecent) {
      final String text = t.destination.trim();
      if (text.isEmpty) continue;
      final String key = catalog?.byText(text)?.id ?? PlaceText.normalize(text);
      if (!seen.add(key)) continue;
      out.add(text);
      if (out.length == max) break;
    }
    return out;
  }
}
