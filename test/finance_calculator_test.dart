import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String usd = 'USD';

Transaction _txn({
  required TransactionType type,
  required double amount,
  String category = 'أخرى',
  DateTime? date,
  String currency = usd,
}) {
  final DateTime d = date ?? DateTime(2026, 3, 10);
  return Transaction(
    id: 't-${DateTime.now().microsecondsSinceEpoch}-${amount.hashCode}',
    date: d,
    type: type,
    category: category,
    amount: Money.fromDouble(amount, currency),
    createdAt: d,
  );
}

void main() {
  group('FinanceCalculator.summarize', () {
    test('empty input yields zeros and savings rate 0', () {
      final FinanceSummary s =
          FinanceCalculator.summarize(<Transaction>[], usd);
      expect(s.income.minorUnits, 0);
      expect(s.expense.minorUnits, 0);
      expect(s.net.minorUnits, 0);
      expect(s.savingsRate, 0);
      expect(s.count, 0);
    });

    test('net = income - expense; savingsRate = (income-expense)/income', () {
      final List<Transaction> txns = <Transaction>[
        _txn(type: TransactionType.income, amount: 1000),
        _txn(type: TransactionType.expense, amount: 400),
      ];
      final FinanceSummary s = FinanceCalculator.summarize(txns, usd);
      expect(s.income, Money.fromDouble(1000, usd));
      expect(s.expense, Money.fromDouble(400, usd));
      expect(s.net, Money.fromDouble(600, usd));
      expect(s.savingsRate, closeTo(0.6, 1e-9));
      expect(s.count, 2);
    });

    test('zero income with expenses gives savingsRate 0 (no divide-by-zero)', () {
      final FinanceSummary s = FinanceCalculator.summarize(
        <Transaction>[_txn(type: TransactionType.expense, amount: 250)],
        usd,
      );
      expect(s.savingsRate, 0);
      expect(s.net, Money.fromDouble(-250, usd));
    });

    test('transactions in another currency are ignored', () {
      final List<Transaction> txns = <Transaction>[
        _txn(type: TransactionType.income, amount: 1000),
        _txn(type: TransactionType.income, amount: 5000, currency: 'DZD'),
      ];
      final FinanceSummary s = FinanceCalculator.summarize(txns, usd);
      expect(s.income, Money.fromDouble(1000, usd));
      expect(s.count, 1);
    });
  });

  group('FinanceCalculator.categoryTotals', () {
    test('aggregates per category, descending', () {
      final List<Transaction> txns = <Transaction>[
        _txn(type: TransactionType.expense, amount: 100, category: 'الطعام'),
        _txn(type: TransactionType.expense, amount: 50, category: 'الطعام'),
        _txn(type: TransactionType.expense, amount: 300, category: 'السكن'),
        _txn(type: TransactionType.income, amount: 900, category: 'راتب أساسي'),
      ];
      final List<CategoryTotal> totals = FinanceCalculator.categoryTotals(
        txns,
        TransactionType.expense,
        usd,
      );
      expect(totals.length, 2);
      expect(totals.first.category, 'السكن');
      expect(totals.first.amount, Money.fromDouble(300, usd));
      expect(totals[1].category, 'الطعام');
      expect(totals[1].amount, Money.fromDouble(150, usd));
    });
  });

  group('FinanceCalculator.monthlyTotals', () {
    test('buckets by month for the requested year', () {
      final List<Transaction> txns = <Transaction>[
        _txn(type: TransactionType.income, amount: 200, date: DateTime(2026, 1, 5)),
        _txn(type: TransactionType.expense, amount: 80, date: DateTime(2026, 1, 20)),
        _txn(type: TransactionType.income, amount: 500, date: DateTime(2025, 1, 1)),
      ];
      final List<MonthPoint> points =
          FinanceCalculator.monthlyTotals(txns, 2026, usd);
      expect(points.length, 12);
      expect(points[0].income, Money.fromDouble(200, usd));
      expect(points[0].expense, Money.fromDouble(80, usd));
      expect(points[0].net, Money.fromDouble(120, usd));
      // February empty.
      expect(points[1].income.minorUnits, 0);
    });
  });
}
