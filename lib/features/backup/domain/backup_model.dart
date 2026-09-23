import 'dart:convert';

import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// A complete, portable snapshot of one user's data.
///
/// This is the on-disk backup format. It is deliberately backend-agnostic and
/// pure (no Flutter/IO deps) so it can be unit-tested and reused when a real
/// backend replaces the local dev store.
class BackupData {
  const BackupData({
    required this.exportedAt,
    required this.baseCurrency,
    required this.transactions,
    required this.budgets,
    required this.customIncome,
    required this.customExpense,
    this.goals = const <Goal>[],
    this.debts = const <Debt>[],
    this.projects = const <Project>[],
  });

  /// Bump when the on-disk shape changes in a breaking way. Adding optional
  /// sections (goals, debts, projects) is not breaking: older files simply
  /// don't have them and load with those lists empty.
  static const int schemaVersion = 1;

  final DateTime exportedAt;
  final String baseCurrency;
  final List<Transaction> transactions;
  final List<BudgetTarget> budgets;
  final List<String> customIncome;
  final List<String> customExpense;
  final List<Goal> goals;
  final List<Debt> debts;
  final List<Project> projects;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'app': 'SmartBudget',
        'exportedAt': exportedAt.toIso8601String(),
        'baseCurrency': baseCurrency,
        'transactions':
            transactions.map((Transaction t) => t.toJson()).toList(),
        'budgets': budgets.map((BudgetTarget b) => b.toJson()).toList(),
        'goals': goals.map((Goal g) => g.toJson()).toList(),
        'debts': debts.map((Debt d) => d.toJson()).toList(),
        'projects': projects.map((Project p) => p.toJson()).toList(),
        'customCategories': <String, dynamic>{
          'income': customIncome,
          'expense': customExpense,
        },
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> cc =
        (json['customCategories'] as Map<dynamic, dynamic>?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return BackupData(
      exportedAt:
          DateTime.tryParse((json['exportedAt'] as String?) ?? '') ??
              DateTime.now(),
      baseCurrency: (json['baseCurrency'] as String?) ?? 'USD',
      transactions: _list<Transaction>(
          json['transactions'], Transaction.fromJson),
      budgets: _list<BudgetTarget>(json['budgets'], BudgetTarget.fromJson),
      customIncome: _strings(cc['income']),
      customExpense: _strings(cc['expense']),
      goals: _list<Goal>(json['goals'], Goal.fromJson),
      debts: _list<Debt>(json['debts'], Debt.fromJson),
      projects: _list<Project>(json['projects'], Project.fromJson),
    );
  }

  static List<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toList() : const <String>[];

  static List<T> _list<T>(
    Object? v,
    T Function(Map<String, dynamic>) from,
  ) =>
      v is List
          ? v
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> e) => from(e.cast<String, dynamic>()))
              .toList()
          : <T>[];
}

/// Pure (de)serialization for [BackupData] and a CSV view of transactions.
abstract final class BackupCodec {
  static String encodeJson(BackupData data) =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  static BackupData decodeJson(String raw) {
    final Object? obj = jsonDecode(raw);
    if (obj is! Map<String, dynamic>) {
      throw const FormatException('Not a SmartBudget backup file.');
    }
    const List<String> sections = <String>[
      'transactions',
      'budgets',
      'goals',
      'debts',
      'projects',
    ];
    if (!sections.any(obj.containsKey)) {
      throw const FormatException('Backup file is missing expected data.');
    }
    return BackupData.fromJson(obj);
  }

  /// A spreadsheet-friendly export of transactions (RFC 4180 quoting).
  static String transactionsToCsv(List<Transaction> txns) {
    const List<String> header = <String>[
      'id',
      'date',
      'type',
      'category',
      'amount',
      'currency',
      'description',
      'paymentMethod',
      'notes',
    ];
    final StringBuffer b = StringBuffer()
      ..writeln(header.map(_csvField).join(','));
    for (final Transaction t in txns) {
      b.writeln(<String>[
        t.id,
        t.date.toIso8601String(),
        t.type.name,
        t.category,
        t.amount.asDouble.toString(),
        t.amount.currencyCode,
        t.description,
        t.paymentMethod ?? '',
        t.notes ?? '',
      ].map(_csvField).join(','));
    }
    return b.toString();
  }

  static String _csvField(String v) {
    if (v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
