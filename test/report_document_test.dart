/// The whole page, built the way the app builds it: real figures, real
/// translations, real category names. What the reader sees is decided here,
/// so this is where it is checked.
library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/reports/data/report_document.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/reports/domain/report_range.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

const String _cur = 'DZD';
Money _m(int major) => Money(major * 100, _cur);

Transaction _t(int year, int month, int major, TransactionType type,
        String category) =>
    Transaction(
      id: '$year-$month-$category-$major',
      date: DateTime(year, month, 12),
      category: category,
      amount: _m(major),
      type: type,
      createdAt: DateTime(year, month, 12),
    );

final List<Transaction> _txns = <Transaction>[
  _t(2025, 12, 80000, TransactionType.income, 'راتب أساسي'),
  _t(2025, 12, 71000, TransactionType.expense, 'الطعام'),
  _t(2026, 1, 70000, TransactionType.income, 'راتب أساسي'),
  _t(2026, 1, 15000, TransactionType.income, 'عمل حر'),
  _t(2026, 1, 25000, TransactionType.expense, 'السكن'),
  _t(2026, 1, 20000, TransactionType.expense, 'الطعام'),
  _t(2026, 1, 17900, TransactionType.expense, 'النقل'),
];

ReportFigures _figures({
  ReportPeriod period = ReportPeriod.monthly,
  int sub = 1,
  int year = 2026,
  List<Transaction>? transactions,
  List<BudgetTarget> budgets = const <BudgetTarget>[],
  DebtSummary? debts,
  double? health,
}) =>
    ReportFigures.build(
      range: ReportRange(period: period, year: year, sub: sub),
      currency: _cur,
      transactions: transactions ?? _txns,
      budgets: budgets,
      debts: debts,
      healthScore: health,
    );

ReportPdfData _doc(
  AppLang lang, {
  ReportFigures? figures,
  String? insight,
}) =>
    ReportDocument.build(
      figures: figures ?? _figures(),
      l: lookupAppLocalizations(Locale(lang.code)),
      lang: lang,
      now: DateTime(2026, 11, 3),
      insight: insight,
    );

void main() {
  group('the page, in the reader\'s language', () {
    test('Arabic reads right to left and names its own month', () {
      final ReportPdfData d = _doc(AppLang.ar);
      expect(d.isRtl, isTrue);
      expect(d.subtitle, contains('يناير'));
      expect(d.subtitle, contains('2026'));
      expect(d.generatedLabel, contains('نوفمبر'));
      expect(d.kpis.first.label, 'إجمالي الدخل');
      expect(d.comparisonTitle, 'مقارنة بالفترة السابقة');
      expect(d.topTitle, 'أكبر فئات الإنفاق');
    });

    test('English reads left to right with the same figures', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.isRtl, isFalse);
      expect(d.subtitle, contains('January'));
      expect(d.generatedLabel, contains('November'));
      expect(d.kpis.first.label, 'Total Income');
      expect(d.kpis.first.value, _doc(AppLang.ar).kpis.first.value,
          reason: 'the language changes the words, never the money');
    });

    test('French and Turkish come through their own translations', () {
      expect(
          _doc(AppLang.fr).comparisonTitle, 'Comparé à la période précédente');
      expect(_doc(AppLang.tr).topTitle, 'En büyük harcama kategorileri');
      expect(_doc(AppLang.fr).subtitle, contains('janvier'));
    });

    test('categories are named, never shown as their keys', () {
      final ReportPdfData ar = _doc(AppLang.ar);
      final ReportPdfData en = _doc(AppLang.en);
      // Categories are stored under their Arabic names; every other
      // language reads them through the catalogue.
      expect(en.expenses.map((ReportRow r) => r.label),
          containsAll(<String>['Housing', 'Groceries', 'Transport']));
      expect(ar.expenses.map((ReportRow r) => r.label),
          containsAll(<String>['السكن', 'الطعام', 'النقل']));
      expect(en.income.first.label, 'Base salary');
    });

    test('a quarter, a half and a year each name themselves', () {
      String sub(ReportPeriod p, int s) =>
          _doc(AppLang.en, figures: _figures(period: p, sub: s)).subtitle;
      expect(sub(ReportPeriod.quarterly, 1), contains('Q1'));
      expect(sub(ReportPeriod.halfYearly, 2), isNotEmpty);
      expect(sub(ReportPeriod.yearly, 1), contains('2026'));
      expect(sub(ReportPeriod.yearly, 1), isNot(contains('—')),
          reason: 'a year has no sub-period to name');
    });
  });

  group('what the page shows', () {
    test('the four headline figures, in order', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.kpis.length, 4);
      expect(d.kpis[0].value, contains('85'));
      expect(d.kpis[1].value, contains('62'));
      expect(d.kpis[3].value, contains('26'));
    });

    test('the comparison carries both periods and the move', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.hasComparison, isTrue);
      expect(d.comparison.length, 4);
      final ReportComparisonRow income = d.comparison.first;
      expect(income.before, contains('80'));
      expect(income.change, '+6.3%');
      expect(income.up, isTrue);
    });

    test('spending less is shown as the good direction', () {
      final ReportComparisonRow expenses = _doc(AppLang.en).comparison[1];
      expect(expenses.change, startsWith('-'));
      expect(expenses.up, isTrue, reason: 'down is up, for spending');
    });

    test('the savings rate moves in points, not in percent of a percent', () {
      final ReportComparisonRow rate = _doc(AppLang.en).comparison[3];
      // 11.25% -> 26.0%, which is 14.75 points.
      expect(rate.change, contains('14.8'));
      expect(rate.change, contains('pts'));
    });

    test('a move too small to print is not shown as a direction', () {
      // January 2026 against a December with the same figures to a decimal:
      // the page must not read "-0.0" in red.
      final ReportPdfData d = _doc(
        AppLang.en,
        figures: _figures(transactions: <Transaction>[
          _t(2025, 12, 80000, TransactionType.income, 'راتب أساسي'),
          _t(2025, 12, 60000, TransactionType.expense, 'الطعام'),
          _t(2026, 1, 80001, TransactionType.income, 'راتب أساسي'),
          _t(2026, 1, 60001, TransactionType.expense, 'الطعام'),
        ]),
      );
      for (final ReportComparisonRow r in d.comparison) {
        expect(r.change, isNot(startsWith('-0.0')), reason: r.label);
      }
      expect(d.comparison.last.change, isNot(contains('-')));
      expect(d.comparison.last.up, isNull, reason: 'flat is not a direction');
    });

    test('a first period says so instead of showing an empty table', () {
      final ReportPdfData d =
          _doc(AppLang.en, figures: _figures(year: 2025, sub: 12));
      expect(d.comparison, isEmpty);
      expect(d.hasComparison, isTrue, reason: 'the line is still printed');
      expect(d.noComparisonLabel, 'No earlier period to compare with');
    });

    test('the year chart is twelve months of real totals', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.trend.length, 12);
      expect(d.hasTrend, isTrue);
      expect(d.trend.first.income, 8500000);
      expect(d.trend.first.expense, 6290000);
      expect(d.trend.first.net, 8500000 - 6290000,
          reason: 'the blue bar is the month\'s own left-over');
      expect(d.trend.last.income, 0, reason: 'December 2025 is another year');
    });

    test('the chart says which colour is which, in the page\'s language', () {
      expect(_doc(AppLang.en).trendLegend,
          <String>['Total Income', 'Total Expenses', 'Left over']);
      expect(_doc(AppLang.ar).trendLegend.first, 'إجمالي الدخل');
    });

    test('the largest categories are bars against the largest', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.hasTop, isTrue);
      expect(d.top.first.ratio, 1.0);
      expect(d.top.length, 3);
      expect(d.top[1].ratio, closeTo(20000 / 25000, 1e-9));
      // Sorted, largest first.
      expect(d.top[1].ratio, lessThan(d.top[0].ratio));
    });
  });

  group('the panels appear only when there is something to show', () {
    test('no budget, no debts, no score: no panels at all', () {
      expect(_doc(AppLang.en).panels, isEmpty);
    });

    test('a budget brings its plan, its spend and a meter', () {
      final ReportPdfData d = _doc(
        AppLang.en,
        figures: _figures(budgets: <BudgetTarget>[
          BudgetTarget(
            id: 'b',
            year: 2026,
            month: 1,
            category: 'السكن',
            planned: _m(30000),
            createdAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      expect(d.panels.length, 1);
      final ReportPanel p = d.panels.first;
      expect(p.title, 'Budget');
      expect(p.rows.map((ReportRow r) => r.label),
          <String>['Planned', 'Spent', 'Left']);
      expect(p.meter, closeTo(25000 / 30000, 1e-9));
      expect(p.overMeter, isFalse);
      expect(p.meterLabel, contains('1'), reason: 'one budgeted category');
    });

    test('a budget already overspent is marked as overspent', () {
      final ReportPdfData d = _doc(
        AppLang.en,
        figures: _figures(budgets: <BudgetTarget>[
          BudgetTarget(
            id: 'b',
            year: 2026,
            month: 1,
            category: 'السكن',
            planned: _m(10000),
            createdAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      expect(d.panels.first.overMeter, isTrue);
      // The meter is clamped by the drawing, but the figure stays true.
      expect(d.panels.first.meter, greaterThan(1));
    });

    test('debts and the health score each bring their own panel', () {
      final ReportPdfData d = _doc(
        AppLang.en,
        figures: _figures(
          debts: const DebtSummary(
            owedToMe: Money(1000000, _cur),
            owedByMe: Money(2500000, _cur),
            net: Money(-1500000, _cur),
            openCount: 2,
          ),
          health: 72.4,
        ),
      );
      expect(d.panels.length, 2);
      expect(d.panels[0].title, 'Debts & Loans');
      expect(d.panels[1].rows.first.value, '72');
      expect(d.panels[1].meter, closeTo(0.724, 1e-9));
    });
  });

  group('the written analysis', () {
    test('is absent unless one was written', () {
      final ReportPdfData d = _doc(AppLang.en);
      expect(d.hasInsight, isFalse);
      expect(d.insightTitle, isNull);
    });

    test('brings its own heading when it is there', () {
      final ReportPdfData d = _doc(AppLang.ar, insight: 'الإنفاق 74%.');
      expect(d.hasInsight, isTrue);
      expect(d.insightTitle, 'قراءة في أرقامك');
    });

    test('is asked for under the same period label the page prints', () {
      final ReportFigures f = _figures();
      final String label = ReportDocument.periodText(
          f, lookupAppLocalizations(const Locale('ar')), AppLang.ar);
      expect(_doc(AppLang.ar, figures: f).subtitle, label);
    });
  });

  test('an empty period still produces a complete page', () {
    final ReportPdfData d = _doc(AppLang.ar,
        figures: _figures(sub: 7, transactions: const <Transaction>[]));
    expect(d.kpis.length, 4);
    expect(d.income, isEmpty);
    expect(d.expenses, isEmpty);
    expect(d.top, isEmpty);
    expect(d.hasTop, isFalse);
    expect(d.hasTrend, isFalse, reason: 'no bars worth drawing');
    expect(d.emptyLabel, isNotEmpty);
  });
}
