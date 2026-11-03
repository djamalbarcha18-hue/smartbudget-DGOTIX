/// Turns the figures into the page the PDF builder lays out.
///
/// Every string the document shows is chosen here — titles, category names,
/// amounts, percentages, the date — in the report's own language. Keeping it
/// out of the widget means the whole document can be built in a test, for
/// every language, without a running app.
library;

import 'package:flutter/services.dart' show rootBundle;

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/financial_health/domain/health_engine.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_figures.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

abstract final class ReportDocument {
  /// The whole page, ready to lay out.
  ///
  /// [now] is passed in rather than read from the clock so a test can fix
  /// the date on the page. [insight] is the written analysis when the reader
  /// asked for one and it came back; null leaves that block out entirely.
  static ReportPdfData build({
    required ReportFigures figures,
    required AppLocalizations l,
    required AppLang lang,
    required DateTime now,
    String? logoSvg,
    String? insight,
  }) {
    final FinanceSummary s = figures.summary;
    String money(Money m) => MoneyFormatter.format(m);

    return ReportPdfData(
      logoSvg: logoSvg,
      title: l.navReports,
      subtitle: periodText(figures, l, lang),
      generatedLabel: l.reportGeneratedOn(today(lang, now)),
      kpis: <ReportRow>[
        ReportRow(l.kpiTotalIncome, money(s.income)),
        ReportRow(l.kpiTotalExpenses, money(s.expense)),
        ReportRow(l.kpiNetProfit, money(s.net)),
        ReportRow(l.kpiSavingsRate, MoneyFormatter.percent(s.savingsRate)),
      ],
      excludedNote: figures.hasExcluded
          ? l.reportExcludedNote(
              figures.excludedCount,
              (figures.excludedCurrencies.toList()..sort()).join(' · '),
            )
          : null,
      comparisonTitle: l.reportVsPrevious,
      comparison: _comparison(figures, l, money),
      noComparisonLabel: l.reportNoPrevious,
      panels: _panels(figures, l, money),
      trendTitle: l.sectionIncomeExpenseTrend,
      trend: <ReportTrendPoint>[
        for (final MonthPoint m in figures.year)
          ReportTrendPoint(
            MonthNames.short(lang: lang)[m.monthIndex],
            m.income.minorUnits,
            m.expense.minorUnits,
            m.net.minorUnits,
          ),
      ],
      trendLegend: <String>[
        l.kpiTotalIncome,
        l.kpiTotalExpenses,
        l.kpiNetProfit,
      ],
      risksTitle: l.healthRisks,
      risks: <String>[
        for (final HealthRisk r in figures.risks) _risk(r, l),
      ],
      topTitle: l.reportTopCategories,
      top: _top(figures, lang, money),
      incomeTitle: l.reportIncomeByCategory,
      income: _rows(figures.income, lang),
      expenseTitle: l.reportExpenseByCategory,
      expenses: _rows(figures.expenses, lang),
      emptyLabel: l.emptyTransactionsMessage,
      footer: 'DGOTIX Analytics · SmartBudget',
      isRtl: lang.rtl,
      insightTitle: insight == null ? null : l.reportInsightTitle,
      insight: insight,
    );
  }

  /// "Monthly — January · 2026". Also the label the written analysis is
  /// asked for, so the document and the request name the same period.
  static String periodText(
      ReportFigures figures, AppLocalizations l, AppLang lang) {
    final ReportPeriod period = figures.range.period;
    final int year = figures.range.year;
    if (period == ReportPeriod.yearly) {
      return '${_periodLabel(period, l)} · $year';
    }
    return '${_periodLabel(period, l)} — '
        '${_subLabel(period, figures.range.sub, l, lang)} · $year';
  }

  /// Today, written in the report's own language. `intl` would need its
  /// locale data loaded for twenty-three languages; the app already keeps
  /// month names for all of them.
  static String today(AppLang lang, DateTime now) {
    return '${now.day} ${MonthNames.full(lang: lang)[now.month - 1]} '
        '${now.year}';
  }

  /// The DGOTIX mark, or null when the asset cannot be read — a report must
  /// not fail over its own logo.
  static Future<String?> logo() async {
    try {
      return await rootBundle.loadString('assets/brand/dgotix-logo.svg');
    } catch (_) {
      return null;
    }
  }

  /// This period beside the one before it. Empty when there is no earlier
  /// period: the document then prints the "nothing to compare" line.
  static List<ReportComparisonRow> _comparison(
    ReportFigures f,
    AppLocalizations l,
    String Function(Money) money,
  ) {
    final FinanceSummary? was = f.previous;
    if (was == null) return const <ReportComparisonRow>[];

    String pct(PeriodChange c) {
      final double? r = c.ratio;
      if (r == null) return money(c.delta);
      if (_roundsToZero(r * 100)) return '0.0%';
      final String sign = r >= 0 ? '+' : '';
      return '$sign${(r * 100).toStringAsFixed(1)}%';
    }

    // A move too small to print is not a direction. Without this a month
    // that gained 0.004 points would be flagged in red as a fall, and the
    // page would read "-0.0".
    bool? dir(PeriodChange c, {bool invert = false}) {
      if (c.isFlat) return null;
      final double? r = c.ratio;
      if (r != null && _roundsToZero(r * 100)) return null;
      return invert ? !c.isUp : c.isUp;
    }

    // Spending less is the good direction, so the arrow is inverted for it:
    // colour follows what the figure means, not which way it moved.
    return <ReportComparisonRow>[
      ReportComparisonRow(l.kpiTotalIncome, money(f.summary.income),
          money(was.income), pct(f.incomeChange!),
          up: dir(f.incomeChange!)),
      ReportComparisonRow(l.kpiTotalExpenses, money(f.summary.expense),
          money(was.expense), pct(f.expenseChange!),
          up: dir(f.expenseChange!, invert: true)),
      ReportComparisonRow(l.kpiNetProfit, money(f.summary.net), money(was.net),
          pct(f.netChange!),
          up: dir(f.netChange!)),
      ReportComparisonRow(
        l.kpiSavingsRate,
        MoneyFormatter.percent(f.summary.savingsRate),
        MoneyFormatter.percent(was.savingsRate),
        l.reportPointsChange(_points(f.savingsRateChange!)),
        up: _roundsToZero(f.savingsRateChange! * 100)
            ? null
            : f.savingsRateChange! > 0,
      ),
    ];
  }

  /// A risk as the health screen words it, so the two never disagree about
  /// what the same finding means.
  static String _risk(HealthRisk r, AppLocalizations l) => switch (r.kind) {
        RiskKind.negativeCashFlow => l.riskNegativeCashFlow,
        RiskKind.spendingExceedsIncome => l.riskSpendingExceedsIncome,
        RiskKind.highDebtService => l.riskHighDebtService,
        RiskKind.highDebtToIncome => l.riskHighDebtToIncome,
        RiskKind.noEmergencyBuffer => l.riskNoEmergencyBuffer,
        RiskKind.incomeInstability => l.riskIncomeInstability,
      };

  /// Below half of the last printed decimal: the page would show it as zero,
  /// so it is treated as zero everywhere rather than only in the text.
  static bool _roundsToZero(double value) => value.abs() < 0.05;

  /// Percentage points, signed: a savings rate moving 11.3% -> 26.0% rose
  /// by 14.7 points, not by 130%.
  static String _points(double change) {
    final double pts = change * 100;
    if (_roundsToZero(pts)) return '0.0';
    return '${pts >= 0 ? '+' : ''}${pts.toStringAsFixed(1)}';
  }

  /// Budget, debts and health — only the ones the account has something to
  /// show. A panel of zeroes tells the reader nothing.
  static List<ReportPanel> _panels(
    ReportFigures f,
    AppLocalizations l,
    String Function(Money) money,
  ) {
    final List<ReportPanel> out = <ReportPanel>[];

    if (f.budget.hasBudget) {
      final double used = f.budget.used!;
      out.add(ReportPanel(
        title: l.reportBudgetTitle,
        rows: <ReportRow>[
          ReportRow(l.reportPlanned, money(f.budget.planned)),
          ReportRow(l.reportSpent, money(f.budget.spent)),
          ReportRow(l.reportLeft, money(f.budget.remaining)),
        ],
        meter: used,
        overMeter: f.budget.isOver,
        meterLabel: l.reportBudgetUsed(
            MoneyFormatter.percent(used), f.budget.categories),
      ));
    }

    final DebtSummary? d = f.debts;
    if (d != null) {
      out.add(ReportPanel(
        title: l.sectionDebts,
        rows: <ReportRow>[
          ReportRow(l.debtOwedToMe, money(d.owedToMe)),
          ReportRow(l.debtOwedByMe, money(d.owedByMe)),
          ReportRow(l.kpiNetProfit, money(d.net)),
        ],
      ));
    }

    final double? score = f.healthScore;
    if (score != null) {
      out.add(ReportPanel(
        title: l.sectionFinancialHealth,
        rows: <ReportRow>[
          ReportRow(l.healthScore, score.toStringAsFixed(0)),
        ],
        meter: (score / 100).clamp(0.0, 1.0),
      ));
    }

    return out;
  }

  /// The five largest expense categories, as bars against the largest.
  static List<ReportBar> _top(
    ReportFigures f,
    AppLang lang,
    String Function(Money) money,
  ) {
    if (f.expenses.isEmpty) return const <ReportBar>[];
    final int peak = f.expenses.first.amount.minorUnits;
    if (peak <= 0) return const <ReportBar>[];
    return <ReportBar>[
      for (final CategoryTotal t in f.expenses.take(5))
        ReportBar(Catalog.label(t.category, lang: lang), money(t.amount),
            t.amount.minorUnits / peak),
    ];
  }

  static List<ReportRow> _rows(List<CategoryTotal> totals, AppLang lang) =>
      totals
          .map((CategoryTotal t) => ReportRow(
              Catalog.label(t.category, lang: lang),
              MoneyFormatter.format(t.amount)))
          .toList();

  static String _periodLabel(ReportPeriod p, AppLocalizations l) => switch (p) {
        ReportPeriod.monthly => l.periodMonthly,
        ReportPeriod.quarterly => l.periodQuarterly,
        ReportPeriod.halfYearly => l.periodHalfYearly,
        ReportPeriod.yearly => l.periodYearly,
      };

  static String _subLabel(
      ReportPeriod p, int s, AppLocalizations l, AppLang lang) {
    switch (p) {
      case ReportPeriod.monthly:
        return MonthNames.full(lang: lang)[(s - 1).clamp(0, 11)];
      case ReportPeriod.quarterly:
        return lang.pick('الربع $s', 'Q$s',
            fr: 'T$s',
            id: 'K$s',
            es: 'T$s',
            tr: '$s. Çeyrek',
            ms: 'Suku $s',
            ur: 'سہ ماہی $s',
            de: 'Q$s',
            pt: '$sº tri',
            it: 'T$s',
            nl: 'K$s',
            bs: 'K$s',
            sq: 'T$s',
            ru: '$s кв.',
            sw: 'Robo $s',
            ha: 'Kwata $s',
            af: 'K$s',
            fa: 'فصل $s',
            hi: 'तिमाही $s',
            zh: '第$s季度',
            ja: '第$s四半期',
            ko: '$s분기');
      case ReportPeriod.halfYearly:
        return s == 2 ? l.half2 : l.half1;
      case ReportPeriod.yearly:
        return '';
    }
  }
}
