import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/reports/data/report_insight_service.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_insight.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

Money _m(int major) => Money(major * 100, 'DZD');
String _money(Money m) => '${m.minorUnits ~/ 100} DZD';

CategoryTotal _c(String name, int major) =>
    CategoryTotal(category: name, amount: _m(major));

final FinanceSummary _summary = FinanceSummary(
  income: _m(85000),
  expense: _m(62900),
  net: _m(22100),
  savingsRate: 0.26,
  count: 41,
);

String _brief({
  List<CategoryTotal>? income,
  List<CategoryTotal>? expenses,
}) =>
    ReportInsight.brief(
      summary: _summary,
      income: income ?? <CategoryTotal>[_c('راتب', 70000)],
      expenses: expenses ??
          <CategoryTotal>[_c('إيجار السكن', 25000), _c('طعام', 18000)],
      periodLabel: 'سنوي · 2026',
      money: _money,
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
      expect(b, contains('إيجار السكن'));
      expect(b, contains('سنوي · 2026'));
    });

    test('money is formatted by the report, so the two cannot disagree', () {
      expect(_brief(), contains(_money(_summary.income)));
    });

    test('only the biggest categories, so the payload stays small', () {
      final List<CategoryTotal> many = <CategoryTotal>[
        for (int i = 0; i < 40; i++) _c('cat$i', 100 - i),
      ];
      final String b = _brief(expenses: many);
      expect(b, contains('cat0'));
      expect(b.contains('cat$kInsightCategories'), isFalse,
          reason: 'past the cut-off');
      // A rough ceiling: a few hundred words, not a ledger.
      expect(b.length, lessThan(2000));
    });

    test('the shares are worked out for the model, not by it', () {
      final String b = _brief();
      // 62900 of 85000 income.
      expect(b, contains('Expense ratio: 74.0% of income'));
      // 25000 of 62900 expenses, and 18000 of 62900.
      expect(b, contains('39.7%'));
      expect(b, contains('28.6%'));
      // 70000 of 85000 income.
      expect(b, contains('82.4%'));
    });

    test('no income means no expense ratio, not a division by zero', () {
      final String b = ReportInsight.brief(
        summary: FinanceSummary(
          income: _m(0),
          expense: _m(4000),
          net: _m(-4000),
          savingsRate: 0,
          count: 3,
        ),
        income: <CategoryTotal>[],
        expenses: <CategoryTotal>[_c('طعام', 4000)],
        periodLabel: 'شهري',
        money: _money,
      );
      expect(b, contains('not available'));
      expect(b, isNot(contains('Infinity')));
      expect(b, isNot(contains('NaN')));
      // The expense side still carries its shares.
      expect(b, contains('100.0%'));
    });

    test('a category whose side totals zero gets no share at all', () {
      final String b = ReportInsight.brief(
        summary: FinanceSummary(
          income: _m(0),
          expense: _m(0),
          net: _m(0),
          savingsRate: 0,
          count: 0,
        ),
        income: <CategoryTotal>[_c('راتب', 0)],
        expenses: <CategoryTotal>[_c('طعام', 0)],
        periodLabel: 'شهري',
        money: _money,
      );
      expect(b, contains('راتب'));
      expect(b, isNot(contains('NaN')));
      expect(b, isNot(contains('%)')), reason: 'no share in brackets');
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
      final String b =
          _brief(income: <CategoryTotal>[], expenses: <CategoryTotal>[]);
      expect(b, contains('(none)'));
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
