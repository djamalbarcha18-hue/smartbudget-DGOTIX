import 'dart:math';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';

enum DaretFrequency { weekly, monthly }

/// A daret / jam'iya (rotating savings group): every round each member pays
/// [contribution] and one member — in [members] order — collects the pot.
class Daret {
  const Daret({
    required this.id,
    required this.name,
    required this.contribution,
    required this.frequency,
    required this.start,
    required this.members,
    required this.meIndex,
    required this.createdAt,
    this.paidRounds = const <int>{},
    this.payoutReceived = false,
  });

  final String id;
  final String name;

  /// What each member pays per round.
  final Money contribution;
  final DaretFrequency frequency;

  /// Date of the first round (the first payout).
  final DateTime start;

  /// Members in turn order: round i is collected by members[i].
  final List<String> members;

  /// The user's position in [members].
  final int meIndex;

  /// Rounds (0-based) the user has paid their contribution for.
  final Set<int> paidRounds;

  /// Whether the user has collected the pot on their turn.
  final bool payoutReceived;
  final DateTime createdAt;

  int get rounds => members.length;

  /// What the round's collector receives: everyone's contribution.
  Money get pot =>
      Money(contribution.minorUnits * rounds, contribution.currencyCode);

  Daret copyWith({
    String? name,
    Money? contribution,
    DaretFrequency? frequency,
    DateTime? start,
    List<String>? members,
    int? meIndex,
    Set<int>? paidRounds,
    bool? payoutReceived,
  }) =>
      Daret(
        id: id,
        name: name ?? this.name,
        contribution: contribution ?? this.contribution,
        frequency: frequency ?? this.frequency,
        start: start ?? this.start,
        members: members ?? this.members,
        meIndex: meIndex ?? this.meIndex,
        paidRounds: paidRounds ?? this.paidRounds,
        payoutReceived: payoutReceived ?? this.payoutReceived,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'contributionMinor': contribution.minorUnits,
        'currency': contribution.currencyCode,
        'frequency': frequency.name,
        'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        'members': members,
        'meIndex': meIndex,
        'paidRounds': (paidRounds.toList()..sort()),
        'payoutReceived': payoutReceived,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Daret.fromJson(Map<String, dynamic> j) {
    final DateTime s = DateTime.tryParse('${j['start']}') ?? DateTime(2026);
    final List<String> members = ((j['members'] as List<dynamic>?) ??
            const <dynamic>[])
        .whereType<String>()
        .toList();
    return Daret(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      contribution: Money((j['contributionMinor'] as num?)?.toInt() ?? 0,
          (j['currency'] as String?) ?? 'USD'),
      frequency: DaretFrequency.values.firstWhere(
          (DaretFrequency f) => f.name == j['frequency'],
          orElse: () => DaretFrequency.monthly),
      start: DateTime(s.year, s.month, s.day),
      members: members,
      meIndex: ((j['meIndex'] as num?)?.toInt() ?? 0)
          .clamp(0, max(0, members.length - 1)),
      paidRounds: ((j['paidRounds'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<num>()
          .map((num n) => n.toInt())
          .toSet(),
      payoutReceived: (j['payoutReceived'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime(2026),
    );
  }
}

abstract final class DaretMath {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Date of round [i]. Monthly rounds keep the start day, clamped to short
  /// months (a daret starting on the 31st pays on Feb 28/29).
  static DateTime roundDate(Daret d, int i) {
    if (d.frequency == DaretFrequency.weekly) {
      return d.start.add(Duration(days: 7 * i));
    }
    final int m = d.start.month - 1 + i;
    final int year = d.start.year + m ~/ 12;
    final int month = m % 12 + 1;
    final int last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(d.start.day, last));
  }

  static DateTime myTurn(Daret d) => roundDate(d, d.meIndex);

  static DateTime lastRound(Daret d) => roundDate(d, d.rounds - 1);

  /// Rounds whose date has come (today included).
  static int roundsDue(Daret d, DateTime today) {
    final DateTime t = _day(today);
    int n = 0;
    while (n < d.rounds && !roundDate(d, n).isAfter(t)) {
      n++;
    }
    return n;
  }

  static bool finished(Daret d, DateTime today) =>
      _day(today).isAfter(lastRound(d));

  /// The first round from today on, or null once all rounds are past.
  static int? nextRound(Daret d, DateTime today) {
    final DateTime t = _day(today);
    for (int i = 0; i < d.rounds; i++) {
      if (!roundDate(d, i).isBefore(t)) return i;
    }
    return null;
  }

  /// Rounds already due that the user hasn't marked as paid.
  static List<int> overdue(Daret d, DateTime today) => <int>[
        for (int i = 0; i < roundsDue(d, today); i++)
          if (!d.paidRounds.contains(i) && roundDate(d, i).isBefore(_day(today)))
            i,
      ];

  /// The earliest round the user still has to pay (overdue or upcoming).
  static int? nextUnpaid(Daret d) {
    for (int i = 0; i < d.rounds; i++) {
      if (!d.paidRounds.contains(i)) return i;
    }
    return null;
  }

  static Money paid(Daret d) => Money(
      d.contribution.minorUnits * d.paidRounds.where((int i) => i < d.rounds).length,
      d.contribution.currencyCode);

  static Money totalToPay(Daret d) => d.pot;

  /// Alerts: a payment due within [paymentLeadDays], the user's own payout
  /// within [payoutLeadDays].
  static const int paymentLeadDays = 3;
  static const int payoutLeadDays = 7;

  static List<AppAlert> alerts(List<Daret> darets, DateTime now) {
    final DateTime t = _day(now);
    final List<AppAlert> out = <AppAlert>[];
    for (final Daret d in darets) {
      if (d.rounds == 0) continue;
      final int? next = nextUnpaid(d);
      if (next != null) {
        final DateTime due = roundDate(d, next);
        final int days = due.difference(t).inDays;
        if (days >= 0 && days <= paymentLeadDays) {
          out.add(AppAlert(
            kind: AlertKind.daretPayment,
            severity: days <= 1 ? AlertSeverity.medium : AlertSeverity.info,
            subject: d.name,
            amount: d.contribution,
            route: '/daret',
            focusKey: '${d.id}#$next',
            date: due,
          ));
        }
      }
      if (!d.payoutReceived) {
        final DateTime turn = myTurn(d);
        final int days = turn.difference(t).inDays;
        if (days >= 0 && days <= payoutLeadDays) {
          out.add(AppAlert(
            kind: AlertKind.daretPayout,
            severity: AlertSeverity.success,
            subject: d.name,
            amount: d.pot,
            route: '/daret',
            focusKey: d.id,
            date: turn,
          ));
        }
      }
    }
    return out;
  }
}
