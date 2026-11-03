/// Accounting accuracy for the reports: the fourteen cases a period report
/// has to get right before anything else about it matters.
///
/// The rule these all serve: a figure on a report is either correct or the
/// report is worthless. Every case here is one way a period total can go
/// wrong — a day on the wrong side of a boundary, a currency quietly
/// dropped, a record counted twice, a year's worth of months that does not
/// add up to the year.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/reports/domain/report_range.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String base = 'DZD';

Money dzd(int major) => Money(major * 100, base);

int _seq = 0;

Transaction txn({
  required DateTime on,
  required int major,
  TransactionType type = TransactionType.expense,
  String category = 'الطعام',
  String currency = base,
  Money? baseAmount,
  String? id,
}) =>
    Transaction(
      id: id ?? 'tx-${_seq++}',
      date: on,
      type: type,
      category: category,
      amount: Money(major * 100, currency),
      baseAmount: baseAmount,
      createdAt: on,
    );

ReportFigures figuresFor(
  ReportPeriod period,
  int year,
  int sub,
  List<Transaction> txns, {
  List<BudgetTarget> budgets = const <BudgetTarget>[],
}) =>
    ReportFigures.build(
      range: ReportRange(period: period, year: year, sub: sub),
      currency: base,
      transactions: txns,
      budgets: budgets,
    );

void main() {
  group('1-3 · the edges of a period', () {
    test('the last instant of the last day belongs to its own month', () {
      final List<Transaction> t = <Transaction>[
        txn(on: DateTime(2026, 1, 31, 23, 59, 59), major: 1000),
      ];
      expect(figuresFor(ReportPeriod.monthly, 2026, 1, t).summary.expense,
          dzd(1000));
      expect(
          figuresFor(ReportPeriod.monthly, 2026, 2, t).summary.expense, dzd(0));
    });

    test('the first instant of the next day belongs to the next month', () {
      final List<Transaction> t = <Transaction>[
        txn(on: DateTime(2026, 2, 1), major: 1000),
      ];
      expect(
          figuresFor(ReportPeriod.monthly, 2026, 1, t).summary.expense, dzd(0));
      expect(figuresFor(ReportPeriod.monthly, 2026, 2, t).summary.expense,
          dzd(1000));
    });

    test('December and January are different years, not just months', () {
      final List<Transaction> t = <Transaction>[
        txn(on: DateTime(2025, 12, 31, 23, 59), major: 700),
        txn(on: DateTime(2026, 1, 1, 0, 0, 1), major: 300),
      ];
      final ReportFigures dec = figuresFor(ReportPeriod.monthly, 2025, 12, t);
      final ReportFigures jan = figuresFor(ReportPeriod.monthly, 2026, 1, t);
      expect(dec.summary.expense, dzd(700));
      expect(jan.summary.expense, dzd(300));
      // And January's comparison reaches back across the year line.
      expect(jan.previous?.expense, dzd(700));
      expect(dec.hasComparison, isFalse, reason: 'nothing before it');
    });

    test('a date is read by its own calendar day, whatever the clock', () {
      // The ledger stores wall-clock dates; a transaction recorded a minute
      // before midnight must not slide into the next month on a device set
      // to another zone.
      final Transaction t = txn(on: DateTime(2026, 3, 31, 23, 59), major: 50);
      final Transaction roundTripped = Transaction.fromJson(t.toJson());
      expect(roundTripped.date.year, 2026);
      expect(roundTripped.date.month, 3);
      expect(roundTripped.date.day, 31);
      expect(
          figuresFor(ReportPeriod.monthly, 2026, 3, <Transaction>[roundTripped])
              .summary
              .expense,
          dzd(50));
    });
  });

  group('4-7 · thin and lopsided periods', () {
    test('a year with gaps reports the months it has', () {
      final List<Transaction> t = <Transaction>[
        txn(on: DateTime(2026, 2, 5), major: 100),
        txn(on: DateTime(2026, 9, 5), major: 200),
      ];
      final ReportFigures y = figuresFor(ReportPeriod.yearly, 2026, 1, t);
      expect(y.summary.expense, dzd(300));
      expect(
          y.year.where((MonthPoint m) => m.expense.minorUnits > 0).length, 2);
      expect(y.year.length, 12, reason: 'the empty months are still months');
    });

    test('a month with nothing in it is zero, not an error', () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 5, const <Transaction>[]);
      expect(f.summary.income, dzd(0));
      expect(f.summary.expense, dzd(0));
      expect(f.summary.net, dzd(0));
      expect(f.summary.savingsRate, 0);
      expect(f.summary.count, 0);
      expect(f.income, isEmpty);
      expect(f.expenses, isEmpty);
    });

    test('income with no expenses saves all of it', () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 4, <Transaction>[
        txn(
            on: DateTime(2026, 4, 2),
            major: 5000,
            type: TransactionType.income,
            category: 'راتب أساسي'),
      ]);
      expect(f.summary.net, dzd(5000));
      expect(f.summary.savingsRate, 1.0);
    });

    test('expenses with no income is a deficit, and no savings rate', () {
      final ReportFigures f = figuresFor(ReportPeriod.monthly, 2026, 4,
          <Transaction>[txn(on: DateTime(2026, 4, 2), major: 5000)]);
      expect(f.summary.net, dzd(-5000));
      expect(f.summary.savingsRate, 0,
          reason: 'a rate of nothing is not -infinity');
    });
  });

  group('8 · money that only moved', () {
    test('the report is built from transactions alone', () {
      // Moving money between your own wallets, and correcting a wallet, are
      // WalletMove records in their own store — never transactions. The
      // engine cannot see them, and this is what keeps that true.
      const List<String> mustNotAppear = <String>[
        'WalletMove',
        'wallets/domain',
        'MoveKind',
      ];
      for (final String path in <String>[
        'lib/features/reports/domain/report_figures.dart',
        'lib/features/transactions/domain/finance_calculator.dart',
      ]) {
        final String src = File(path).readAsStringSync();
        for (final String word in mustNotAppear) {
          expect(src.contains(word), isFalse, reason: '$path mentions $word');
        }
      }
    });

    test('a wallet\'s opening balance is not income', () {
      // It lives on the wallet, not in the ledger, so an account that starts
      // with 200,000 in the bank does not report 200,000 of income.
      final String src =
          File('lib/features/wallets/domain/wallet.dart').readAsStringSync();
      expect(src.contains('final Money opening'), isTrue);
      expect(
          figuresFor(ReportPeriod.yearly, 2026, 1, const <Transaction>[])
              .summary
              .income,
          dzd(0));
    });
  });

  group('9-10 · currencies and refunds', () {
    test('a foreign amount counts at the rate recorded with it', () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 6, <Transaction>[
        txn(
          on: DateTime(2026, 6, 3),
          major: 100,
          currency: 'EUR',
          baseAmount: dzd(15000),
        ),
      ]);
      expect(f.summary.expense, dzd(15000),
          reason: 'the day\'s rate, not today\'s');
    });

    test('a foreign amount with no recorded rate is left out, never guessed',
        () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 6, <Transaction>[
        txn(on: DateTime(2026, 6, 3), major: 100, currency: 'EUR'),
        txn(on: DateTime(2026, 6, 4), major: 2000),
      ]);
      expect(f.summary.expense, dzd(2000));
    });

    test('what was left out is counted and named, not silently dropped', () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 6, <Transaction>[
        txn(on: DateTime(2026, 6, 3), major: 100, currency: 'EUR'),
        txn(on: DateTime(2026, 6, 4), major: 50, currency: 'USD'),
        txn(
          on: DateTime(2026, 6, 5),
          major: 30,
          currency: 'EUR',
          baseAmount: dzd(4500),
        ),
        txn(on: DateTime(2026, 6, 6), major: 2000),
      ]);
      expect(f.excludedCount, 2);
      expect(f.excludedCurrencies, <String>{'EUR', 'USD'});
      expect(f.hasExcluded, isTrue);
      // The ones that could be valued are still counted.
      expect(f.summary.expense, dzd(6500));
    });

    test('nothing excluded is the quiet case', () {
      final ReportFigures f = figuresFor(ReportPeriod.monthly, 2026, 6,
          <Transaction>[txn(on: DateTime(2026, 6, 4), major: 2000)]);
      expect(f.hasExcluded, isFalse);
      expect(f.excludedCount, 0);
      expect(f.excludedCurrencies, isEmpty);
    });

    test('a refund recorded as income raises income, by design', () {
      // SmartBudget has no contra-entry: a refund is an income category.
      // The report states both sides as the ledger holds them rather than
      // restating the user's own records.
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 7, <Transaction>[
        txn(on: DateTime(2026, 7, 1), major: 1000),
        txn(
            on: DateTime(2026, 7, 2),
            major: 400,
            type: TransactionType.income,
            category: 'استرداد أو تعويض'),
      ]);
      expect(f.summary.expense, dzd(1000));
      expect(f.summary.income, dzd(400));
      expect(f.summary.net, dzd(-600));
    });

    test('a negative amount reduces its own side, so a cancellation nets out',
        () {
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 7, <Transaction>[
        txn(on: DateTime(2026, 7, 1), major: 1000),
        txn(on: DateTime(2026, 7, 2), major: -1000),
      ]);
      expect(f.summary.expense, dzd(0));
      expect(f.summary.net, dzd(0));
    });
  });

  group('11 · the same record, twice', () {
    test('one id counts once, however often it appears in the list', () {
      final Transaction one =
          txn(on: DateTime(2026, 8, 3), major: 1200, id: 'dup');
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 8, <Transaction>[one, one]);
      expect(f.summary.expense, dzd(1200));
      expect(f.summary.count, 1);
    });

    test('an edited copy of the same id does not double the total', () {
      final Transaction a =
          txn(on: DateTime(2026, 8, 3), major: 1200, id: 'same');
      final Transaction b = a.copyWith(amount: dzd(1500));
      final ReportFigures f =
          figuresFor(ReportPeriod.monthly, 2026, 8, <Transaction>[a, b]);
      expect(f.summary.expense.minorUnits, anyOf(120000, 150000),
          reason: 'one of them, never both');
      expect(f.summary.count, 1);
    });

    test('a report is a pure function of the ledger it is given', () {
      // Editing or deleting after a report was exported changes the next
      // one: nothing is cached between the ledger and the figures.
      final List<Transaction> ledger = <Transaction>[
        txn(on: DateTime(2026, 8, 3), major: 1200, id: 'a'),
        txn(on: DateTime(2026, 8, 4), major: 800, id: 'b'),
      ];
      expect(figuresFor(ReportPeriod.monthly, 2026, 8, ledger).summary.expense,
          dzd(2000));
      ledger.removeWhere((Transaction t) => t.id == 'b');
      expect(figuresFor(ReportPeriod.monthly, 2026, 8, ledger).summary.expense,
          dzd(1200));
    });
  });

  group('12-14 · the periods have to agree', () {
    // A year of ordinary movement: every month different, a deficit month,
    // an empty month, two currencies, and a day on each boundary.
    final List<Transaction> year = <Transaction>[
      for (int month = 1; month <= 12; month++) ...<Transaction>[
        if (month != 6) // June has no income: a deficit month
          txn(
            on: DateTime(2026, month, 1),
            major: 60000 + month * 1000,
            type: TransactionType.income,
            category: 'راتب أساسي',
          ),
        if (month != 9) // September is empty of expenses
          txn(
            on: DateTime(2026, month, _lastDay(2026, month)),
            major: 40000 + month * 700,
            category: 'السكن',
          ),
        if (month.isEven)
          txn(
            on: DateTime(2026, month, 15),
            major: 100,
            currency: 'EUR',
            baseAmount: dzd(15000),
          ),
      ],
      // Neighbouring years, which must never leak in.
      txn(on: DateTime(2025, 12, 31), major: 99999),
      txn(on: DateTime(2027, 1, 1), major: 88888),
    ];

    FinanceSummary sumOf(ReportPeriod p, int sub) =>
        figuresFor(p, 2026, sub, year).summary;

    FinanceSummary add(Iterable<FinanceSummary> parts) {
      int income = 0, expense = 0, count = 0;
      for (final FinanceSummary s in parts) {
        income += s.income.minorUnits;
        expense += s.expense.minorUnits;
        count += s.count;
      }
      return FinanceSummary(
        income: Money(income, base),
        expense: Money(expense, base),
        net: Money(income - expense, base),
        savingsRate: income == 0 ? 0 : (income - expense) / income,
        count: count,
      );
    }

    void sameTotals(FinanceSummary a, FinanceSummary b, String what) {
      expect(a.income, b.income, reason: '$what: income');
      expect(a.expense, b.expense, reason: '$what: expenses');
      expect(a.net, b.net, reason: '$what: net');
      expect(a.count, b.count, reason: '$what: count');
      expect(a.savingsRate, closeTo(b.savingsRate, 1e-12),
          reason: '$what: savings rate');
    }

    test('twelve monthly reports add up to the annual report', () {
      sameTotals(
        add(<FinanceSummary>[
          for (int m = 1; m <= 12; m++) sumOf(ReportPeriod.monthly, m),
        ]),
        sumOf(ReportPeriod.yearly, 1),
        'year',
      );
    });

    test('three monthly reports add up to their quarter', () {
      for (int q = 1; q <= 4; q++) {
        sameTotals(
          add(<FinanceSummary>[
            for (int m = (q - 1) * 3 + 1; m <= q * 3; m++)
              sumOf(ReportPeriod.monthly, m),
          ]),
          sumOf(ReportPeriod.quarterly, q),
          'Q$q',
        );
      }
    });

    test('six monthly reports add up to their half', () {
      for (int h = 1; h <= 2; h++) {
        sameTotals(
          add(<FinanceSummary>[
            for (int m = (h - 1) * 6 + 1; m <= h * 6; m++)
              sumOf(ReportPeriod.monthly, m),
          ]),
          sumOf(ReportPeriod.halfYearly, h),
          'H$h',
        );
      }
    });

    test('the quarters add up to the year, and the halves do too', () {
      final FinanceSummary y = sumOf(ReportPeriod.yearly, 1);
      sameTotals(
          add(<FinanceSummary>[
            for (int q = 1; q <= 4; q++) sumOf(ReportPeriod.quarterly, q),
          ]),
          y,
          'quarters');
      sameTotals(
          add(<FinanceSummary>[
            for (int h = 1; h <= 2; h++) sumOf(ReportPeriod.halfYearly, h),
          ]),
          y,
          'halves');
    });

    test('the neighbouring years stay out of all of it', () {
      final FinanceSummary y = sumOf(ReportPeriod.yearly, 1);
      expect(y.expense.minorUnits, isNot(contains(99999)));
      expect(figuresFor(ReportPeriod.yearly, 2025, 1, year).summary.expense,
          dzd(99999));
      expect(figuresFor(ReportPeriod.yearly, 2027, 1, year).summary.expense,
          dzd(88888));
    });

    test('the category tables add up to the headline totals as well', () {
      final ReportFigures y = figuresFor(ReportPeriod.yearly, 2026, 1, year);
      int sum(List<CategoryTotal> t) =>
          t.fold<int>(0, (int a, CategoryTotal c) => a + c.amount.minorUnits);
      expect(sum(y.expenses), y.summary.expense.minorUnits);
      expect(sum(y.income), y.summary.income.minorUnits);
    });

    test('the month chart adds up to the year as well', () {
      final ReportFigures y = figuresFor(ReportPeriod.yearly, 2026, 1, year);
      int sum(int Function(MonthPoint) pick) =>
          y.year.fold<int>(0, (int a, MonthPoint m) => a + pick(m));
      expect(sum((MonthPoint m) => m.income.minorUnits),
          y.summary.income.minorUnits);
      expect(sum((MonthPoint m) => m.expense.minorUnits),
          y.summary.expense.minorUnits);
    });
  });
}

int _lastDay(int year, int month) => DateTime(year, month + 1, 0).day;
