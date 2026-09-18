import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// A planned (expected) expense amount for one category in one month.
///
/// Mirrors SmartBudget V1's "المصروف المتوقّع" column. Uniquely identified by
/// (year, month, category). Feeds the budget-discipline health indicator and
/// the planned-vs-actual view on the Monthly Budget screen.
@immutable
class BudgetTarget {
  const BudgetTarget({
    required this.id,
    required this.year,
    required this.month, // 1..12
    required this.category,
    required this.planned,
    required this.createdAt,
  });

  final String id;
  final int year;
  final int month;
  final String category;
  final Money planned;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'year': year,
        'month': month,
        'category': category,
        'plannedMinor': planned.minorUnits,
        'currency': planned.currencyCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetTarget.fromJson(Map<String, dynamic> json) {
    return BudgetTarget(
      id: json['id'] as String,
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 1,
      category: (json['category'] as String?) ?? '',
      planned: Money(
        (json['plannedMinor'] as num?)?.toInt() ?? 0,
        (json['currency'] as String?) ?? 'USD',
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
