import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/reports/data/report_insight_service.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_insight.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/reports/domain/report_range.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String _cur = 'DZD';

Money _m(int major) => Money(major * 100, _cur);
String _money(Money m) => '${m.minorUnits ~/ 100} DZD';

/// Categories are stored under their Arabic names. They reach the brief
/// already read through the catalogue, exactly as the tables print them: a
/// commentary naming a category differently from the table beside it would
/// be a bug the reader sees.
String _label(String key) => Catalog.label(key, lang: AppLang.en);

Transaction _t({
  required int year,
  required int month,
  required int major,
  required TransactionType type,
  String category = 'الطعام',
}) =>
    Transaction(
      id: '$year-$month-$major-${type.name}-$category',
      date: DateTime(year, month, 10),
      category: category,
      amount: _m(major),
      type: type,
      createdAt: DateTime(year, month, 10),
    );

/// January 2026: 85,000 in, 62,900 out. December 2025: 80,000 in, 71,000 out.
final List<Transaction> _txns = <Transaction>[
  _t(
      year: 2025,
      month: 12,
      major: 80000,
      type: TransactionType.income,
      category: 'راتب أساسي'),
  _t(year: 2025, month: 12, major: 71000, type: TransactionType.expense),
  _t(
      year: 2026,
      month: 1,
      major: 70000,
      type: TransactionType.income,
      category: 'راتب أساسي'),
  _t(
      year: 2026,
      month: 1,
      major: 15000,
      type: TransactionType.income,
      category: 'عمل حر'),
  _t(
      year: 2026,
      month: 1,
      major: 25000,
      type: TransactionType.expense,
      category: 'السكن'),
  _t(
      year: 2026,
      month: 1,
      major: 37900,
      type: TransactionType.expense,
      category: 'الطعام'),
];

ReportFigures _figures({
  List<Transaction>? transactions,
  List<BudgetTarget> budgets = const <BudgetTarget>[],
  DebtSummary? debts,
  double? health,
  int month = 1,
  int year = 2026,
}) =>
    ReportFigures.build(
      range: ReportRange(period: ReportPeriod.monthly, year: year, sub: month),
      currency: _cur,
      transactions: transactions ?? _txns,
      budgets: budgets,
      debts: debts,
      healthScore: health,
    );

String _brief({ReportFigures? figures}) => ReportInsight.brief(
      figures: figures ?? _figures(),
      periodLabel: 'شهري — يناير · 2026',
      money: _money,
      label: _label,
    );

void main() {
  group('the privacy promise, checked in the source', () {
    // The hint shown beside the switch says transactions are not sent. These
    // two make that structural rather than a habit: there is no parameter a
    // transaction could arrive through, and no import to build one from.
    test('neither file knows what a Transaction is', () {
      for (final String path in <String>[
        'lib/features/reports/domain/report_insight.dart',
        'lib/features/reports/data/report_insight_service.dart',
      ]) {
        final String src = File(path).readAsStringSync();
        expect(src.contains('domain/transaction.dart'), isFalse,
            reason: '$path imports the transaction model');
        expect(src.contains('Transaction'), isFalse,
            reason: '$path mentions Transaction');
      }
    });

    test('the brief carries no date, note, wallet or account field', () {
      final String b = _brief();
      for (final String leak in <String>['note', 'wallet', 'account', 'id:']) {
        expect(b.toLowerCase(), isNot(contains(leak)), reason: leak);
      }
    });
  });

  group('what is sent', () {
    test('the figures the report already prints, and nothing else', () {
      final String b = _brief();
      expect(b, contains('85000 DZD'));
      expect(b, contains('62900 DZD'));
      expect(b, contains('26.0%'));
      expect(b, contains('Housing'),
          reason: 'read through the catalogue, not the stored key');
      expect(b, isNot(contains('السكن')));
      expect(b, contains('شهري — يناير · 2026'));
    });

    test('money is formatted by the report, so the two cannot disagree', () {
      expect(_brief(), contains(_money(_m(85000))));
    });

    test('only the biggest categories, so the payload stays small', () {
      final String b = _brief(
        figures: _figures(
          transactions: <Transaction>[
            for (int i = 0; i < 40; i++)
              _t(
                year: 2026,
                month: 1,
                major: 4000 - i,
                type: TransactionType.expense,
                category: 'cat$i',
              ),
          ],
        ),
      );
      expect(b, contains('cat0'));
      expect(b.contains('cat$kInsightCategories'), isFalse,
          reason: 'past the cut-off');
      // A rough ceiling: a page of figures, never a ledger — this is what
      // keeps the request cheap however many categories an account has.
      expect(b.length, lessThan(2000));
    });

    test('the shares are worked out for the model, not by it', () {
      final String b = _brief();
      // 62900 of 85000 income.
      expect(b, contains('Expense ratio: 74.0% of income'));
      // 25000 of 62900 expenses, and 37900 of 62900.
      expect(b, contains('39.7%'));
      expect(b, contains('60.3%'));
      // 70000 of 85000 income.
      expect(b, contains('82.4%'));
    });

    test('no income means no expense ratio, not a division by zero', () {
      final String b = _brief(
        figures: _figures(
          month: 5,
          transactions: <Transaction>[
            _t(
                year: 2026,
                month: 5,
                major: 4000,
                type: TransactionType.expense),
          ],
        ),
      );
      expect(b, contains('not available'));
      expect(b, isNot(contains('Infinity')));
      expect(b, isNot(contains('NaN')));
      // The expense side still carries its shares.
      expect(b, contains('100.0%'));
    });

    test('an empty side is stated, never divided by', () {
      final String b = _brief(
        figures: _figures(month: 7, transactions: const <Transaction>[]),
      );
      expect(b, isNot(contains('NaN')));
      expect(b, isNot(contains('Infinity')));
      expect(b, contains('(none)'));
    });

    test('the move against the period before travels with the figures', () {
      final String b = _brief();
      expect(b, contains('Against the period before:'));
      // 85,000 against 80,000 in, 62,900 against 71,000 out.
      expect(b, contains('+6.3%'));
      expect(b, contains('-11.4%'));
      expect(b, contains('was 80000 DZD'));
      // 26.0% against 11.3%: points, never a percentage of a percentage.
      expect(b, contains('points'));
    });

    test('a first period says there is nothing to compare with', () {
      final String b = _brief(
        figures: _figures(
          month: 12,
          year: 2025,
          transactions: <Transaction>[
            _t(year: 2025, month: 12, major: 100, type: TransactionType.income),
          ],
        ),
      );
      expect(b, contains('no earlier period on record'));
      expect(b, isNot(contains('was ')));
    });

    test('the budget travels as plan, spend and share', () {
      final String b = _brief(
        figures: _figures(budgets: <BudgetTarget>[
          BudgetTarget(
            id: 'b1',
            year: 2026,
            month: 1,
            category: 'السكن',
            planned: _m(20000),
            createdAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      expect(b, contains('Budget: planned 20000 DZD'));
      expect(b, contains('spent 25000 DZD'));
      expect(b, contains('over plan'));
    });

    test('no budget is stated plainly, not left out', () {
      expect(_brief(), contains('Budget: none set'));
    });

    test('debts and the health score travel when the account has them', () {
      final String b = _brief(
        figures: _figures(
          debts: const DebtSummary(
            owedToMe: Money(1000000, _cur),
            owedByMe: Money(2500000, _cur),
            net: Money(-1500000, _cur),
            openCount: 3,
          ),
          health: 72.4,
        ),
      );
      expect(b, contains('Debts outstanding today'));
      expect(b, contains('3 open'));
      expect(b, contains('Financial health score: 72 out of 100'));
    });

    test('an account with neither sends neither', () {
      final String b = _brief();
      expect(b, isNot(contains('Debts outstanding')));
      expect(b, isNot(contains('Financial health score')));
    });

    test('the register asked for is analysis, brief and numeric', () {
      final String p = ReportInsight.prompt('Arabic');
      expect(p, contains('financial analysis'));
      expect(p, contains('At most 80 words'));
      expect(p, contains('three steps'));
      expect(p, contains('two sentences'));
      // Motivating by arithmetic, and nothing literary.
      expect(p, contains('not by praise'));
      expect(p, contains('No congratulating'));
      expect(p, contains('No metaphor'));
      expect(p, contains('do not recompute'));
    });

    test('an empty period says so rather than sending an empty shape', () {
      expect(
        _brief(
            figures: _figures(month: 9, transactions: const <Transaction>[])),
        contains('(none)'),
      );
    });

    test('the writing is asked for in the report\'s own language', () {
      expect(ReportInsight.prompt('Arabic'), contains('in Arabic'));
      expect(languageNameOf(AppLang.ar), 'Arabic');
      expect(languageNameOf(AppLang.ur), 'Urdu');
    });

    test('every app language has a name for the model', () {
      for (final AppLang lang in AppLang.values) {
        expect(languageNameOf(lang).trim(), isNotEmpty, reason: lang.code);
      }
    });
  });

  group('what comes back', () {
    test('markdown the model adds anyway is stripped', () {
      const String raw = '## What happened\n'
          '- You spent **62,900** on housing.\n'
          '* Savings held at 26%.\n';
      final String? out = ReportInsight.clean(raw);
      expect(out, isNotNull);
      expect(out, isNot(contains('#')));
      expect(out, isNot(contains('*')));
      expect(out, isNot(contains('- ')));
      expect(out, contains('62,900'));
    });

    test('an empty or markup-only answer becomes no commentary at all', () {
      expect(ReportInsight.clean(null), isNull);
      expect(ReportInsight.clean(''), isNull);
      expect(ReportInsight.clean('   \n\n  '), isNull);
      expect(ReportInsight.clean('###\n---'), isNotNull,
          reason: 'a rule line is text; only nothing is nothing');
    });

    test('blank lines are dropped but the sentences keep their order', () {
      expect(ReportInsight.clean('one\n\n\ntwo\nthree'), 'one\ntwo\nthree');
    });

    test('a commentary that runs long is cut to whole lines, not mid-word', () {
      final String raw =
          List<String>.generate(20, (int i) => 'line $i').join('\n');
      final String out = ReportInsight.clean(raw)!;
      final List<String> kept = out.split('\n');
      expect(kept.length, kInsightMaxLines);
      expect(kept.first, 'line 0');
      expect(kept.last, 'line ${kInsightMaxLines - 1}');
      // Nothing was truncated inside a line.
      for (final String line in kept) {
        expect(line, matches(RegExp(r'^line \d+$')));
      }
    });

    test('two sentences and three steps pass through untouched', () {
      const String raw = 'Expenses took 74.0% of income; housing alone 39.7%.\n'
          'The savings rate held at 26.0%.\n'
          'Housing: cap at 22000 DZD, frees 3000 DZD.\n'
          'Food: cap at 16000 DZD, frees 2000 DZD.\n'
          'Transport: cap at 5000 DZD, frees 1200 DZD.';
      final String? out = ReportInsight.clean(raw);
      expect(out, raw, reason: 'five lines is inside the cap');
    });
  });

  group('the report without it', () {
    test('a document with no commentary is the document we had', () {
      const ReportPdfData plain = ReportPdfData(
        title: 't',
        subtitle: 's',
        generatedLabel: 'g',
        kpis: <ReportRow>[],
        incomeTitle: 'i',
        income: <ReportRow>[],
        expenseTitle: 'e',
        expenses: <ReportRow>[],
        emptyLabel: '-',
        footer: 'f',
        isRtl: true,
      );
      expect(plain.hasInsight, isFalse);
    });

    test('a half-filled commentary is treated as none', () {
      const ReportPdfData noTitle = ReportPdfData(
        title: 't',
        subtitle: 's',
        generatedLabel: 'g',
        kpis: <ReportRow>[],
        incomeTitle: 'i',
        income: <ReportRow>[],
        expenseTitle: 'e',
        expenses: <ReportRow>[],
        emptyLabel: '-',
        footer: 'f',
        isRtl: true,
        insight: 'text with no heading',
      );
      expect(noTitle.hasInsight, isFalse);

      const ReportPdfData blank = ReportPdfData(
        title: 't',
        subtitle: 's',
        generatedLabel: 'g',
        kpis: <ReportRow>[],
        incomeTitle: 'i',
        income: <ReportRow>[],
        expenseTitle: 'e',
        expenses: <ReportRow>[],
        emptyLabel: '-',
        footer: 'f',
        isRtl: true,
        insightTitle: 'Reading',
        insight: '   ',
      );
      expect(blank.hasInsight, isFalse);
    });

    test('both halves present is a commentary', () {
      const ReportPdfData full = ReportPdfData(
        title: 't',
        subtitle: 's',
        generatedLabel: 'g',
        kpis: <ReportRow>[],
        incomeTitle: 'i',
        income: <ReportRow>[],
        expenseTitle: 'e',
        expenses: <ReportRow>[],
        emptyLabel: '-',
        footer: 'f',
        isRtl: true,
        insightTitle: 'Reading your figures',
        insight: 'Housing took a third.',
      );
      expect(full.hasInsight, isTrue);
    });
  });
}
