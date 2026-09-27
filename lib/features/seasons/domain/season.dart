import 'dart:math';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

/// Recurring spending seasons. Ramadan and Eid al-Adha follow the Hijri
/// calendar (they move ~11 days earlier every Gregorian year).
enum SeasonKind { ramadan, eidAdha, schoolStart, summer, custom }

typedef SeasonWindow = ({DateTime start, DateTime end});

/// A saving plan for ONE occurrence of a season (e.g. Ramadan 1448).
class SeasonPlan {
  const SeasonPlan({
    required this.id,
    required this.kind,
    required this.start,
    required this.end,
    required this.budget,
    required this.saved,
    required this.createdAt,
    this.name = '',
  });

  final String id;
  final SeasonKind kind;

  /// Only for [SeasonKind.custom] (the presets are named by the app).
  final String name;
  final DateTime start;
  final DateTime end;
  final Money budget;

  /// Set aside so far for this season.
  final Money saved;
  final DateTime createdAt;

  SeasonPlan copyWith({Money? budget, Money? saved, String? name}) =>
      SeasonPlan(
        id: id,
        kind: kind,
        name: name ?? this.name,
        start: start,
        end: end,
        budget: budget ?? this.budget,
        saved: saved ?? this.saved,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'name': name,
        'start': _ymd(start),
        'end': _ymd(end),
        'budgetMinor': budget.minorUnits,
        'savedMinor': saved.minorUnits,
        'currency': budget.currencyCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SeasonPlan.fromJson(Map<String, dynamic> j) {
    final String cur = (j['currency'] as String?) ?? 'USD';
    return SeasonPlan(
      id: j['id'] as String,
      kind: SeasonKind.values.firstWhere((SeasonKind k) => k.name == j['kind'],
          orElse: () => SeasonKind.custom),
      name: (j['name'] as String?) ?? '',
      start: _parseDay(j['start']),
      end: _parseDay(j['end']),
      budget: Money((j['budgetMinor'] as num?)?.toInt() ?? 0, cur),
      saved: Money((j['savedMinor'] as num?)?.toInt() ?? 0, cur),
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime(2026),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(Object? v) {
    final DateTime d = DateTime.tryParse('$v') ?? DateTime(2026);
    return DateTime(d.year, d.month, d.day);
  }
}

abstract final class SeasonCalendar {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isHijri(SeasonKind k) =>
      k == SeasonKind.ramadan || k == SeasonKind.eidAdha;

  /// The window of [kind] in [year] (a Hijri year for Ramadan / Eid al-Adha,
  /// Gregorian otherwise). Windows include the run-up spending: Ramadan runs to
  /// the end of Eid al-Fitr, Eid al-Adha covers the first 13 days of
  /// Dhu al-Hijjah (the sacrifice is usually bought beforehand), and the school
  /// season covers supplies bought before the start of term.
  static SeasonWindow window(SeasonKind kind, int year) => switch (kind) {
        SeasonKind.ramadan => (
            start: HijriDate(year, 9, 1).toGregorian(),
            end: HijriDate(year, 10, 3).toGregorian(),
          ),
        SeasonKind.eidAdha => (
            start: HijriDate(year, 12, 1).toGregorian(),
            end: HijriDate(year, 12, 13).toGregorian(),
          ),
        SeasonKind.schoolStart => (
            start: DateTime(year, 8, 20),
            end: DateTime(year, 9, 30),
          ),
        SeasonKind.summer => (
            start: DateTime(year, 7, 1),
            end: DateTime(year, 8, 31),
          ),
        SeasonKind.custom => throw ArgumentError('custom has no calendar'),
      };

  static int _yearOf(SeasonKind kind, DateTime d) =>
      isHijri(kind) ? HijriDate.fromGregorian(d).year : d.year;

  /// The current or next occurrence (the first whose end is today or later).
  static SeasonWindow next(SeasonKind kind, DateTime today) {
    final DateTime t = _day(today);
    final int y = _yearOf(kind, t);
    for (int i = -1; i <= 2; i++) {
      final SeasonWindow w = window(kind, y + i);
      if (!w.end.isBefore(t)) return w;
    }
    return window(kind, y + 1);
  }

  /// The most recent occurrence that has fully ended before [today].
  static SeasonWindow previous(SeasonKind kind, DateTime today) {
    final DateTime t = _day(today);
    final int y = _yearOf(kind, t);
    for (int i = 1; i >= -2; i--) {
      final SeasonWindow w = window(kind, y + i);
      if (w.end.isBefore(t)) return w;
    }
    return window(kind, y - 1);
  }

  /// The occurrence right after [w] (for "plan the next one").
  static SeasonWindow after(SeasonKind kind, SeasonWindow w) =>
      next(kind, w.end.add(const Duration(days: 1)));

  /// Hijri year of an occurrence starting on [start] (for labels).
  static int hijriYear(DateTime start) => HijriDate.fromGregorian(start).year;
}

enum SeasonStatus { upcoming, active, ended }

abstract final class SeasonMath {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static SeasonStatus status(SeasonPlan p, DateTime today) {
    final DateTime t = _day(today);
    if (t.isBefore(p.start)) return SeasonStatus.upcoming;
    if (t.isAfter(p.end)) return SeasonStatus.ended;
    return SeasonStatus.active;
  }

  static int daysUntil(SeasonPlan p, DateTime today) =>
      max(0, p.start.difference(_day(today)).inDays);

  static Money remainingToSave(SeasonPlan p) => Money(
      max(0, p.budget.minorUnits - p.saved.minorUnits), p.budget.currencyCode);

  /// What to set aside each month to be ready on the first day. Counts the
  /// months left, rounding up, and at least one.
  static Money monthlyNeeded(SeasonPlan p, DateTime today) {
    final int months = max(1, (daysUntil(p, today) / 30).ceil());
    return Money((remainingToSave(p).minorUnits / months).ceil(),
        p.budget.currencyCode);
  }

  /// Expenses recorded inside [w] (base currency only, like every total).
  static Money spentIn(
    SeasonWindow w,
    List<Transaction> txns,
    String currency,
  ) {
    final List<Transaction> inside = txns.where((Transaction t) {
      if (t.type != TransactionType.expense) return false;
      final DateTime d = _day(t.date);
      return !d.isBefore(w.start) && !d.isAfter(w.end);
    }).toList();
    return FinanceCalculator.summarize(inside, currency).expense;
  }

  static Money spent(SeasonPlan p, List<Transaction> txns, String currency) =>
      spentIn((start: p.start, end: p.end), txns, currency);
}
