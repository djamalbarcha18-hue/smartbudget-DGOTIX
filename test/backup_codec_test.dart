import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
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
      goals: <Goal>[
        Goal(
          id: 'g1',
          name: 'Emergency fund',
          target: Money.fromDouble(5000, usd),
          saved: Money.fromDouble(1200, usd),
          deadline: DateTime(2027, 1, 1),
          createdAt: DateTime(2026, 1, 5),
        ),
      ],
      debts: <Debt>[
        Debt(
          id: 'd1',
          party: 'Ali',
          type: DebtType.lent,
          original: Money.fromDouble(400, usd),
          paid: Money.fromDouble(100, usd),
          dueDate: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
      projects: <Project>[
        Project(
          id: 'p1',
          name: 'Laptop',
          target: Money.fromDouble(1500, usd),
          saved: Money.fromDouble(300, usd),
          horizon: ProjectHorizon.mid,
          createdAt: DateTime(2026, 2, 2),
        ),
      ],
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

    test('goals, debts and projects survive a round-trip', () {
      final BackupData back =
          BackupCodec.decodeJson(BackupCodec.encodeJson(_sample()));
      expect(back.goals.single.id, 'g1');
      expect(back.goals.single.saved, Money.fromDouble(1200, usd));
      expect(back.goals.single.deadline, DateTime(2027, 1, 1));
      expect(back.debts.single.party, 'Ali');
      expect(back.debts.single.type, DebtType.lent);
      expect(back.debts.single.paid, Money.fromDouble(100, usd));
      expect(back.projects.single.name, 'Laptop');
      expect(back.projects.single.horizon, ProjectHorizon.mid);
    });

    test('backups made before goals/debts/projects were added still load', () {
      final BackupData d = BackupCodec.decodeJson(
          '{"schemaVersion":1,"transactions":[],"budgets":[]}');
      expect(d.goals, isEmpty);
      expect(d.debts, isEmpty);
      expect(d.projects, isEmpty);
    });

    test('a backup holding only goals is still recognised', () {
      final BackupData d = BackupCodec.decodeJson('{"goals":[]}');
      expect(d.goals, isEmpty);
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
