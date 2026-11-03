/// The written part of a report: what the figures mean, and what to do next.
///
/// **What leaves the device.** Only the totals that are already printed on the
/// report — four figures and the category lines. Never a transaction, a note,
/// a merchant, a date, a wallet or an account. That is enforced by shape, not
/// by discipline: [brief] accepts the computed summary and the category
/// totals, and there is no parameter through which a transaction could reach
/// it.
///
/// Pure (no Flutter, no network) so the whole payload can be asserted in a
/// test — see test/report_insight_test.dart.
library;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';

/// How many category lines are sent. The long tail of tiny categories adds
/// tokens and tells the reader nothing, so the biggest few are enough.
const int kInsightCategories = 8;

/// How many lines of commentary survive [ReportInsight.clean].
///
/// The commentary is meant to be two sentences and three steps. A word cap
/// in the prompt is a request, not a guarantee; dropping whole trailing
/// lines here keeps it short without ever cutting a sentence in half.
const int kInsightMaxLines = 6;

abstract final class ReportInsight {
  /// The figures to be explained, as compact lines.
  ///
  /// [money] formats an amount the way the report prints it, so the writing
  /// and the table cannot disagree about a number.
  static String brief({
    required FinanceSummary summary,
    required List<CategoryTotal> income,
    required List<CategoryTotal> expenses,
    required String periodLabel,
    required String Function(Money) money,
  }) {
    // Every share is worked out here rather than left to the model: a
    // language model is a poor calculator, and a commentary that disagrees
    // with its own table is worse than no commentary. Nothing new leaves the
    // device — each ratio is derived from the four figures and the category
    // lines the report already prints.
    String percentOf(int part, int whole) =>
        '${(part * 100 / whole).toStringAsFixed(1)}%';

    String lines(List<CategoryTotal> totals, int whole) {
      final List<CategoryTotal> top = totals.take(kInsightCategories).toList();
      if (top.isEmpty) return '  (none)';
      return top.map((CategoryTotal t) {
        final String share =
            whole > 0 ? ' (${percentOf(t.amount.minorUnits, whole)})' : '';
        return '  ${t.category}: ${money(t.amount)}$share';
      }).join('\n');
    }

    final int incomeMinor = summary.income.minorUnits;
    final int expenseMinor = summary.expense.minorUnits;

    return <String>[
      'Period: $periodLabel',
      'Income: ${money(summary.income)}',
      'Expenses: ${money(summary.expense)}',
      'Net: ${money(summary.net)}',
      'Savings rate: ${(summary.savingsRate * 100).toStringAsFixed(1)}%',
      if (incomeMinor > 0)
        'Expense ratio: ${percentOf(expenseMinor, incomeMinor)} of income'
      else
        'Expense ratio: not available (no income recorded)',
      'Income by source (share of income):',
      lines(income, incomeMinor),
      'Expenses by category (share of expenses):',
      lines(expenses, expenseMinor),
    ].join('\n');
  }

  /// What the assistant is asked to write.
  ///
  /// The register is deliberate: a financial analyst's note, not prose. Two
  /// sentences of ratio and three costed steps, every claim carrying a figure
  /// that is already in [brief]. Motivation comes from arithmetic — what the
  /// next figure could be and what it is worth — because praise without a
  /// number tells the reader nothing they can act on.
  ///
  /// [languageName] is the report's own language, in English, so the writing
  /// matches the rest of the page rather than the device's locale.
  static String prompt(String languageName) => <String>[
        'Write the analyst commentary for this financial report, in '
            '$languageName.',
        'Reader: the account holder. Register: financial analysis. Concise, '
            'quantitative, forward-looking.',
        'Exactly two parts, in this order, and nothing else:',
        '1. Reading: two sentences. Each one states a ratio or an amount from '
            'the figures below - the expense ratio, the savings rate, or the '
            'share of the largest category - and names that category.',
        '2. Next: exactly three steps, one line each, under twelve words. '
            'Each line names one category, one target figure, and the amount '
            'it frees over the period.',
        'At most 80 words in total. Shorter is better.',
        'Use only the figures below. Copy them as printed; do not recompute, '
            'convert or re-round them, and never state a figure that is not '
            'there.',
        'Motivate by arithmetic, not by praise: name the figure the next '
            'period could reach and what it is worth. No congratulating, no '
            'scolding, no encouragement without a number.',
        'No metaphor, no imagery, no adjectives of mood, no narrative. No '
            'headings, no markdown, no bullet characters, no greeting, no '
            'sign-off, no mention of being an AI.',
        'If the period is empty, or the figures are too few to carry a '
            'ratio, say that in one sentence and stop.',
      ].join('\n');

  /// Tidies what came back so it can be set as plain paragraphs.
  ///
  /// Models add a stray heading or a bullet even when told not to; stripping
  /// them here keeps the PDF's typography ours. An answer that arrives empty
  /// (or as nothing but markup) returns null, which leaves the report exactly
  /// as it is without the commentary. An answer that runs past
  /// [kInsightMaxLines] keeps its first lines and loses the rest, so the
  /// brevity the prompt asks for is enforced rather than hoped for.
  static String? clean(String? raw) {
    if (raw == null) return null;
    final List<String> kept = <String>[];
    for (String line in raw.split('\n')) {
      line = line
          .replaceAll(RegExp(r'^\s*#{1,6}\s*'), '')
          .replaceAll(RegExp(r'^\s*[-*•]\s*'), '')
          .replaceAll(RegExp(r'\*\*?'), '')
          .trim();
      if (line.isEmpty) continue;
      kept.add(line);
      if (kept.length == kInsightMaxLines) break;
    }
    final String out = kept.join('\n');
    return out.isEmpty ? null : out;
  }
}
