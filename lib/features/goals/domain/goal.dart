import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// A savings goal (domain entity).
///
/// `saved` is DERIVED — it accumulates only through explicit contributions
/// (never a free-typed seed), matching SmartBudget V1 where the saved column is
/// computed, not manually entered. Legit user inputs: name, target, deadline.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.deadline,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Money target;
  final Money saved;
  final DateTime? deadline;
  final DateTime createdAt;

  Goal copyWith({
    String? name,
    Money? target,
    Money? saved,
    DateTime? deadline,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'targetMinor': target.minorUnits,
        'savedMinor': saved.minorUnits,
        'currency': target.currencyCode,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    final String currency = (json['currency'] as String?) ?? 'USD';
    return Goal(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      target: Money((json['targetMinor'] as num?)?.toInt() ?? 0, currency),
      saved: Money((json['savedMinor'] as num?)?.toInt() ?? 0, currency),
      deadline: (json['deadline'] as String?) == null
          ? null
          : DateTime.tryParse(json['deadline'] as String),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
