import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// How often a recurring transaction repeats.
enum RecurrenceFrequency { weekly, monthly, quarterly, halfYearly, yearly }

/// A transaction that repeats on a schedule (salary, rent, a subscription…).
///
/// The rule is a template: each due occurrence is posted as an ordinary
/// [Transaction], so every calculator, report and export keeps working
/// unchanged. Occurrences are always computed from [startDate] (never from the
/// previous occurrence), so a rule anchored on the 31st lands on the last day
/// of short months and returns to the 31st afterwards instead of drifting.
@immutable
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    this.paymentMethod,
    this.notes,
    this.walletId,
    required this.frequency,
    required this.startDate,
    required this.lastPosted,
    this.active = true,
    this.variableAmount = false,
    required this.createdAt,
  });

  final String id;
  final TransactionType type;
  final String category;
  final Money amount;
  final String description;
  final String? paymentMethod;
  final String? notes;

  /// Wallet each posted occurrence uses; null = the "General" wallet.
  final String? walletId;
  final RecurrenceFrequency frequency;

  /// Date of the first occurrence (the anchor of the schedule).
  final DateTime startDate;

  /// Date of the last occurrence that was posted (or deliberately skipped
  /// while paused). Nothing on or before it is ever posted again.
  final DateTime lastPosted;

  /// Paused rules post nothing.
  final bool active;

  /// The amount changes each time (a performance bonus, a commission…): an
  /// occurrence is never posted on its own. When it falls due the user is
  /// asked for the real amount, and [amount] keeps the latest one as the
  /// estimate for the next.
  final bool variableAmount;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;

  RecurringRule copyWith({
    String? category,
    Money? amount,
    String? description,
    DateTime? lastPosted,
    bool? active,
    bool? variableAmount,
  }) {
    return RecurringRule(
      id: id,
      type: type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod,
      notes: notes,
      walletId: walletId,
      frequency: frequency,
      startDate: startDate,
      lastPosted: lastPosted ?? this.lastPosted,
      active: active ?? this.active,
      variableAmount: variableAmount ?? this.variableAmount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'category': category,
        'amountMinor': amount.minorUnits,
        'currency': amount.currencyCode,
        'description': description,
        'paymentMethod': paymentMethod,
        'notes': notes,
        if (walletId != null) 'walletId': walletId,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'lastPosted': lastPosted.toIso8601String(),
        'active': active,
        if (variableAmount) 'variableAmount': true,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    final DateTime start =
        DateTime.tryParse((json['startDate'] as String?) ?? '') ??
            AppClock.now();
    return RecurringRule(
      id: (json['id'] as String?) ?? '',
      type: TransactionType.values.firstWhere(
        (TransactionType t) => t.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: (json['category'] as String?) ?? '',
      amount: Money(
        (json['amountMinor'] as num?)?.toInt() ?? 0,
        (json['currency'] as String?) ?? 'USD',
      ),
      description: (json['description'] as String?) ?? '',
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
      walletId: json['walletId'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
        (RecurrenceFrequency f) => f.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: start,
      lastPosted:
          DateTime.tryParse((json['lastPosted'] as String?) ?? '') ?? start,
      active: (json['active'] as bool?) ?? true,
      variableAmount: (json['variableAmount'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          AppClock.now(),
    );
  }
}
