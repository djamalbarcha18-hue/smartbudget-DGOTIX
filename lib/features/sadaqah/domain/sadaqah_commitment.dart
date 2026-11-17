import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// How often a commitment comes due.
enum SadaqahFrequency { weekly, monthly }

/// What the commitment is for.
enum SadaqahKind { sadaqah, family, sponsorship }

/// A regular gift the user plans for (Sadaqah Planner). Private: kept on
/// this device for the signed-in account, never synced, and its amount and
/// note never appear in a notification.
@immutable
class SadaqahCommitment {
  const SadaqahCommitment({
    required this.id,
    required this.createdAt,
    this.kind = SadaqahKind.sadaqah,
    this.note = '',
    this.amount,
    this.frequency = SadaqahFrequency.weekly,
    this.weekday = DateTime.friday,
    this.dayOfMonth = 1,
    this.hour = 10,
    this.minute = 0,
    this.remind = true,
    this.recordAsExpense = true,
    this.paid = const <String>{},
  });

  final String id;
  final DateTime createdAt;
  final SadaqahKind kind;

  /// The user's own words; shown only on this screen.
  final String note;

  /// Optional: many people give without fixing an amount.
  final Money? amount;
  final SadaqahFrequency frequency;

  /// [DateTime.monday] … [DateTime.sunday] (weekly).
  final int weekday;

  /// 1 … 28 (monthly), so it exists in every month.
  final int dayOfMonth;
  final int hour;
  final int minute;

  /// This commitment's reminder (when reminders are on for the planner).
  final bool remind;

  /// Marking it done also records an expense in "Charity & donations".
  final bool recordAsExpense;

  /// Periods marked done: `W2026-47` (ISO week) or `M2026-11`.
  final Set<String> paid;

  /// The period [d] falls in.
  String periodOf(DateTime d) {
    if (frequency == SadaqahFrequency.monthly) {
      return 'M${d.year}-${d.month.toString().padLeft(2, '0')}';
    }
    final (int year, int week) = isoWeek(d);
    return 'W$year-${week.toString().padLeft(2, '0')}';
  }

  bool isPaidFor(DateTime d) => paid.contains(periodOf(d));

  /// The due moment in the period holding [d].
  DateTime dueInPeriodOf(DateTime d) {
    if (frequency == SadaqahFrequency.monthly) {
      return DateTime(d.year, d.month, dayOfMonth, hour, minute);
    }
    final DateTime monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return DateTime(
        monday.year, monday.month, monday.day + weekday - 1, hour, minute);
  }

  /// The next [count] due moments after [now] in periods not marked done.
  List<DateTime> upcoming(DateTime now, int count) {
    final List<DateTime> out = <DateTime>[];
    DateTime cursor = now;
    for (int i = 0; i < count + 12 && out.length < count; i++) {
      final DateTime due = dueInPeriodOf(cursor);
      if (due.isAfter(now) && !isPaidFor(due)) out.add(due);
      cursor = frequency == SadaqahFrequency.monthly
          ? DateTime(cursor.year, cursor.month + 1)
          : DateTime(cursor.year, cursor.month, cursor.day + 7);
    }
    return out;
  }

  SadaqahCommitment markedPaid(DateTime d) {
    final List<String> all = (<String>{...paid, periodOf(d)}.toList()..sort());
    // The last 60 periods are plenty for the "done" badges.
    return copyWith(
        paid: all.sublist(all.length > 60 ? all.length - 60 : 0).toSet());
  }

  SadaqahCommitment unmarkedPaid(DateTime d) =>
      copyWith(paid: <String>{...paid}..remove(periodOf(d)));

  SadaqahCommitment copyWith({
    SadaqahKind? kind,
    String? note,
    Money? amount,
    bool clearAmount = false,
    SadaqahFrequency? frequency,
    int? weekday,
    int? dayOfMonth,
    int? hour,
    int? minute,
    bool? remind,
    bool? recordAsExpense,
    Set<String>? paid,
  }) =>
      SadaqahCommitment(
        id: id,
        createdAt: createdAt,
        kind: kind ?? this.kind,
        note: note ?? this.note,
        amount: clearAmount ? null : (amount ?? this.amount),
        frequency: frequency ?? this.frequency,
        weekday: weekday ?? this.weekday,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        remind: remind ?? this.remind,
        recordAsExpense: recordAsExpense ?? this.recordAsExpense,
        paid: paid ?? this.paid,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'kind': kind.name,
        'note': note,
        if (amount != null) 'amountMinor': amount!.minorUnits,
        if (amount != null) 'currency': amount!.currencyCode,
        'frequency': frequency.name,
        'weekday': weekday,
        'dayOfMonth': dayOfMonth,
        'hour': hour,
        'minute': minute,
        'remind': remind,
        'recordAsExpense': recordAsExpense,
        'paid': paid.toList(),
      };

  static SadaqahCommitment? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> j = raw.cast<String, dynamic>();
    final Object? id = j['id'];
    if (id is! String || id.isEmpty) return null;
    final int? minor = (j['amountMinor'] as num?)?.toInt();
    final String? currency = j['currency'] as String?;
    int clampInt(Object? v, int lo, int hi, int fallback) {
      final int? n = (v as num?)?.toInt();
      return n == null || n < lo || n > hi ? fallback : n;
    }

    return SadaqahCommitment(
      id: id,
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
          DateTime(2026),
      kind: SadaqahKind.values.firstWhere(
          (SadaqahKind k) => k.name == j['kind'],
          orElse: () => SadaqahKind.sadaqah),
      note: (j['note'] as String?) ?? '',
      amount: minor != null && currency != null ? Money(minor, currency) : null,
      frequency: SadaqahFrequency.values.firstWhere(
          (SadaqahFrequency f) => f.name == j['frequency'],
          orElse: () => SadaqahFrequency.weekly),
      weekday: clampInt(j['weekday'], 1, 7, DateTime.friday),
      dayOfMonth: clampInt(j['dayOfMonth'], 1, 28, 1),
      hour: clampInt(j['hour'], 0, 23, 10),
      minute: clampInt(j['minute'], 0, 59, 0),
      remind: (j['remind'] as bool?) ?? true,
      recordAsExpense: (j['recordAsExpense'] as bool?) ?? true,
      paid: <String>{
        for (final Object? p in (j['paid'] as List<Object?>?) ?? <Object?>[])
          if (p is String) p,
      },
    );
  }

  /// ISO 8601 (year, week) of [d].
  static (int, int) isoWeek(DateTime d) {
    final DateTime day = DateTime.utc(d.year, d.month, d.day);
    final DateTime thursday = day.add(Duration(days: 4 - day.weekday));
    final DateTime firstJan = DateTime.utc(thursday.year);
    return (thursday.year, thursday.difference(firstJan).inDays ~/ 7 + 1);
  }
}

/// When the planner's reminders fire: the next unpaid due moments of every
/// commitment that asks for one, soonest first.
abstract final class SadaqahSchedule {
  /// Per commitment, so marking one done skips only that period.
  static const int perCommitment = 3;

  /// The notification ids the planner may use.
  static const int maxReminders = 60;

  static List<DateTime> plan(
      Iterable<SadaqahCommitment> items, DateTime now) {
    final List<DateTime> times = <DateTime>[
      for (final SadaqahCommitment c in items)
        if (c.remind) ...c.upcoming(now, perCommitment),
    ]..sort();
    return times.take(maxReminders).toList();
  }
}
