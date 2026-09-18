import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// Money lent (to me → an asset) vs borrowed (I owe → a liability).
/// Mirrors SmartBudget V1's "🟢 لي (دائن)" / "🔴 عليّ (مدين)".
enum DebtType { lent, borrowed }

/// Settlement status (as specified for the SaaS): richer than V1's active/done.
enum DebtStatus { active, partiallyPaid, paid, overdue }

/// A debt/loan record (domain entity). `remaining` and `status` are derived by
/// [DebtCalculator] — never stored, matching the SmartBudget approach.
@immutable
class Debt {
  const Debt({
    required this.id,
    required this.party,
    required this.type,
    required this.original,
    required this.paid,
    this.date,
    this.dueDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String party;
  final DebtType type;
  final Money original;
  final Money paid;
  final DateTime? date;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;

  bool get isLent => type == DebtType.lent;

  Debt copyWith({
    String? party,
    DebtType? type,
    Money? original,
    Money? paid,
    DateTime? date,
    DateTime? dueDate,
    String? notes,
  }) {
    return Debt(
      id: id,
      party: party ?? this.party,
      type: type ?? this.type,
      original: original ?? this.original,
      paid: paid ?? this.paid,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'party': party,
        'type': type.name,
        'originalMinor': original.minorUnits,
        'paidMinor': paid.minorUnits,
        'currency': original.currencyCode,
        'date': date?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) {
    final String currency = (json['currency'] as String?) ?? 'USD';
    DateTime? parse(String? s) => (s == null) ? null : DateTime.tryParse(s);
    return Debt(
      id: json['id'] as String,
      party: (json['party'] as String?) ?? '',
      type: DebtType.values.firstWhere(
        (DebtType t) => t.name == json['type'],
        orElse: () => DebtType.borrowed,
      ),
      original: Money((json['originalMinor'] as num?)?.toInt() ?? 0, currency),
      paid: Money((json['paidMinor'] as num?)?.toInt() ?? 0, currency),
      date: parse(json['date'] as String?),
      dueDate: parse(json['dueDate'] as String?),
      notes: json['notes'] as String?,
      createdAt: parse(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }
}
