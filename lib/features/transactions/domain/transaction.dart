import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/app_clock.dart';

/// Income or expense — the two transaction kinds (mirrors SmartBudget).
enum TransactionType { income, expense }

/// A single financial transaction (domain entity).
///
/// `amount` carries its own currency; in P3 all of a user's transactions share
/// the base currency (cross-currency comes with the exchange-rate phase).
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    this.paymentMethod,
    this.notes,
    this.walletId,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final TransactionType type;
  final String category;
  final Money amount;
  final String description;
  final String? paymentMethod;
  final String? notes;

  /// The wallet it moved money in or out of; null = the "General" wallet.
  final String? walletId;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  Transaction copyWith({
    DateTime? date,
    TransactionType? type,
    String? category,
    Money? amount,
    String? description,
    String? paymentMethod,
    String? notes,
    String? walletId,
    bool clearWallet = false,
  }) {
    return Transaction(
      id: id,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      walletId: clearWallet ? null : walletId ?? this.walletId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'type': type.name,
        'category': category,
        'amountMinor': amount.minorUnits,
        'currency': amount.currencyCode,
        'description': description,
        'paymentMethod': paymentMethod,
        'notes': notes,
        if (walletId != null) 'walletId': walletId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
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
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          AppClock.now(),
    );
  }
}
