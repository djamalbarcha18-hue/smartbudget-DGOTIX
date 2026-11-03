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
