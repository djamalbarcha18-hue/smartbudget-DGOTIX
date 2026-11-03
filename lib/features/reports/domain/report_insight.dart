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
    String lines(List<CategoryTotal> totals) {
      final List<CategoryTotal> top = totals.take(kInsightCategories).toList();
      if (top.isEmpty) return '  (none)';
      return top
          .map((CategoryTotal t) => '  ${t.category}: ${money(t.amount)}')
          .join('\n');
    }

    return <String>[
      'Period: $periodLabel',
      'Income: ${money(summary.income)}',
      'Expenses: ${money(summary.expense)}',
      'Net: ${money(summary.net)}',
      'Savings rate: ${(summary.savingsRate * 100).toStringAsFixed(1)}%',
      'Income by source:',
      lines(income),
      'Expenses by category:',
      lines(expenses),
    ].join('\n');
  }

  /// What the assistant is asked to write.
  ///
  /// [languageName] is the report's own language, in English, so the writing
  /// matches the rest of the page rather than the device's locale.
  static String prompt(String languageName) => <String>[
        'Write the commentary for this financial report, in $languageName.',
        'Two short parts, in this order and nothing else:',
        '1. What happened: three or four sentences on where the money went, '
            'what stands out, and how the savings rate reads. Name real '
            'categories and figures from the data.',
        '2. What to do next: exactly three concrete steps, one line each, '
            'each tied to a category or figure above.',
        'Plain sentences. No headings, no markdown, no bullet characters, no '
            'greeting, no sign-off, no mention of being an AI.',
        'Say only what the figures support. If a period is empty or too '
            'short to read, say so in one sentence instead of inventing a '
            'trend.',
      ].join('\n');

  /// Tidies what came back so it can be set as plain paragraphs.
  ///
  /// Models add a stray heading or a bullet even when told not to; stripping
  /// them here keeps the PDF's typography ours. An answer that arrives empty
  /// (or as nothing but markup) returns null, which leaves the report exactly
  /// as it is without the commentary.
  static String? clean(String? raw) {
    if (raw == null) return null;
    final List<String> kept = <String>[];
    for (String line in raw.split('\n')) {
      line = line
          .replaceAll(RegExp(r'^\s*#{1,6}\s*'), '')
          .replaceAll(RegExp(r'^\s*[-*•]\s*'), '')
          .replaceAll(RegExp(r'\*\*?'), '')
          .trim();
      if (line.isNotEmpty) kept.add(line);
    }
    final String out = kept.join('\n');
    return out.isEmpty ? null : out;
  }
}
