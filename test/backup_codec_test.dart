import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String usd = 'USD';

BackupData _sample() => BackupData(
      exportedAt: DateTime.parse('2026-03-10T12:00:00.000'),
      baseCurrency: usd,
      transactions: <Transaction>[
        Transaction(
          id: 't1',
          date: DateTime(2026, 3, 10),
          type: TransactionType.expense,
          category: 'الطعام',
          amount: Money.fromDouble(12.5, usd),
          description: 'lunch, with comma',
          notes: 'quote " test',
          createdAt: DateTime(2026, 3, 10),
        ),
        Transaction(
          id: 't2',
          date: DateTime(2026, 3, 11),
          type: TransactionType.income,
          category: 'راتب أساسي',
          amount: Money.fromDouble(1000, usd),
          createdAt: DateTime(2026, 3, 11),
        ),
      ],
      budgets: <BudgetTarget>[
        BudgetTarget(
          id: 'b1',
          year: 2026,
          month: 3,
          category: 'الطعام',
          planned: Money.fromDouble(300, usd),
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
      customIncome: <String>['محتوى راعٍ'],
      customExpense: <String>['اشتراكات'],
    );

void main() {
  group('BackupCodec JSON round-trip', () {
    test('encode then decode preserves all data', () {
      final BackupData original = _sample();
      final BackupData restored =
          BackupCodec.decodeJson(BackupCodec.encodeJson(original));

      expect(restored.baseCurrency, usd);
      expect(restored.transactions, hasLength(2));
      expect(restored.transactions.first.id, 't1');
      expect(restored.transactions.first.description, 'lunch, with comma');
      expect(restored.transactions.first.notes, 'quote " test');
      expect(restored.transactions.first.amount.minorUnits,
          original.transactions.first.amount.minorUnits);
      expect(restored.budgets, hasLength(1));
      expect(restored.budgets.first.category, 'الطعام');
      expect(restored.customIncome, <String>['محتوى راعٍ']);
      expect(restored.customExpense, <String>['اشتراكات']);
    });

    test('schemaVersion and app marker are written', () {
      final Map<String, dynamic> json = _sample().toJson();
      expect(json['schemaVersion'], BackupData.schemaVersion);
      expect(json['app'], 'SmartBudget');
    });

    test('decoding a non-object throws FormatException', () {
      expect(() => BackupCodec.decodeJson('123'),
          throwsA(isA<FormatException>()));
    });

    test('decoding an unrelated object throws FormatException', () {
      expect(() => BackupCodec.decodeJson('{"foo":"bar"}'),
          throwsA(isA<FormatException>()));
    });

    test('missing optional sections default to empty, not crash', () {
      final BackupData d = BackupCodec.decodeJson('{"transactions":[]}');
      expect(d.transactions, isEmpty);
      expect(d.budgets, isEmpty);
      expect(d.customIncome, isEmpty);
      expect(d.baseCurrency, 'USD');
    });
  });

  group('BackupCodec.transactionsToCsv', () {
    test('has a header row and one row per transaction', () {
      final String csv = BackupCodec.transactionsToCsv(_sample().transactions);
      final List<String> lines = csv.trim().split('\n');
      expect(lines, hasLength(3)); // header + 2
      expect(lines.first, startsWith('id,date,type,category,amount'));
    });

    test('quotes fields containing commas and escapes quotes', () {
      final String csv = BackupCodec.transactionsToCsv(_sample().transactions);
      expect(csv, contains('"lunch, with comma"'));
      expect(csv, contains('"quote "" test"'));
    });
  });
}
