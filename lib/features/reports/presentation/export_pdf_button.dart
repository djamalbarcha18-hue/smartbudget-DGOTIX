import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/reports/application/reports_controller.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';
import 'package:smartbudget/features/billing/application/feature_gate_provider.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/l10n/month_names.dart';

/// Exports the current report as a branded DGOTIX PDF (print / save-as-PDF).
class ExportPdfButton extends ConsumerStatefulWidget {
  const ExportPdfButton({super.key});

  @override
  ConsumerState<ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends ConsumerState<ExportPdfButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool full =
        ref.watch(featureGateProvider(Feature.reportPdf)).allowed;
    return TextButton.icon(
      onPressed: _busy
          ? null
          : full
              ? _export
              : () => PlanLimits.allow(context, Feature.reportPdf),
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              full ? Icons.picture_as_pdf_outlined : Icons.lock_outline_rounded,
              size: 16),
      label: Text(l.reportExportPdf),
    );
  }

  Future<void> _export() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLang lang = appLangOf(context);

    setState(() => _busy = true);
    try {
      final ReportResult report = ref.read(reportResultProvider);
      final ReportPeriod period = ref.read(effectiveReportPeriodProvider);
      final int sub = ref.read(effectiveReportSubProvider);
      final int year = ref.read(selectedYearProvider);
      final FinanceSummary s = report.summary;

      final String periodText = period == ReportPeriod.yearly
          ? '${_periodLabel(period, l)} · $year'
          : '${_periodLabel(period, l)} — ${_subLabel(period, sub, l, lang)} · $year';

      final ReportPdfData data = ReportPdfData(
        title: l.navReports,
        subtitle: periodText,
        generatedLabel: l.reportGeneratedOn(
            DateFormat('yyyy-MM-dd').format(AppClock.now())),
        kpis: <ReportRow>[
          ReportRow(l.kpiTotalIncome, MoneyFormatter.format(s.income)),
          ReportRow(l.kpiTotalExpenses, MoneyFormatter.format(s.expense)),
          ReportRow(l.kpiNetProfit, MoneyFormatter.format(s.net)),
          ReportRow(l.kpiSavingsRate, MoneyFormatter.percent(s.savingsRate)),
        ],
        incomeTitle: l.reportIncomeByCategory,
        income: _rows(report.incomeCategories, lang),
        expenseTitle: l.reportExpenseByCategory,
        expenses: _rows(report.expenseCategories, lang),
        emptyLabel: l.emptyTransactionsMessage,
        footer: 'DGOTIX Analytics · SmartBudget',
        isRtl: lang.rtl,
      );

      // Urdu letters aren't in Tajawal: Urdu reports use Noto Naskh Arabic.
      // Cyrillic isn't either: Russian reports are set in Inter.
      final pw.Font base;
      final pw.Font bold;
      if (lang == AppLang.ru) {
        base = pw.Font.ttf(
            await rootBundle.load('assets/google_fonts/Inter-Regular.ttf'));
        bold = pw.Font.ttf(
            await rootBundle.load('assets/google_fonts/Inter-SemiBold.ttf'));
      } else {
        final String family =
            lang == AppLang.ur ? 'NotoNaskhArabic' : 'Tajawal';
        base = pw.Font.ttf(
            await rootBundle.load('assets/fonts/$family-Regular.ttf'));
        bold = pw.Font.ttf(
            await rootBundle.load('assets/fonts/$family-Bold.ttf'));
      }
      // Only where letters are missing, to keep files small: Tajawal for the
      // digits and Latin of Urdu reports and any Arabic in Russian ones,
      // Inter for Turkish ğ ş İ, Bosnian č ć đ, Hausa ɓ ɗ ƙ ƴ and currency
      // signs Tajawal lacks (₹ ₺ ₦ ₫ ฿ ₱ Kč…).
      final bool interLetters = switch (lang) {
        AppLang.tr || AppLang.bs || AppLang.ha => true,
        _ => false,
      };
      final List<pw.Font> fallback = <pw.Font>[
        if (lang == AppLang.ur || lang == AppLang.ru)
          pw.Font.ttf(
              await rootBundle.load('assets/fonts/Tajawal-Regular.ttf')),
        if (lang != AppLang.ru &&
            (interLetters || _needsInter(s.income.currency.symbol)))
          pw.Font.ttf(
              await rootBundle.load('assets/google_fonts/Inter-Regular.ttf')),
      ];
      final Uint8List bytes = await ReportPdfBuilder.build(data,
          base: base, bold: bold, fallback: fallback);
      await Printing.layoutPdf(
        name: 'DGOTIX-Analytics-$year.pdf',
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.reportPdfFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A currency sign with a character beyond Latin-1, Arabic and €.
  static bool _needsInter(String symbol) => symbol.runes.any((int r) =>
      r > 0xFF && (r < 0x0600 || r > 0x06FF) && r != 0x20AC);

  List<ReportRow> _rows(List<CategoryTotal> totals, AppLang lang) => totals
      .map((CategoryTotal t) =>
          ReportRow(Catalog.label(t.category, lang: lang), MoneyFormatter.format(t.amount)))
      .toList();

  String _periodLabel(ReportPeriod p, AppLocalizations l) => switch (p) {
        ReportPeriod.monthly => l.periodMonthly,
        ReportPeriod.quarterly => l.periodQuarterly,
        ReportPeriod.halfYearly => l.periodHalfYearly,
        ReportPeriod.yearly => l.periodYearly,
      };

  String _subLabel(ReportPeriod p, int s, AppLocalizations l, AppLang lang) {
    switch (p) {
      case ReportPeriod.monthly:
        return MonthNames.full(lang: lang)[(s - 1).clamp(0, 11)];
      case ReportPeriod.quarterly:
        return lang.pick('الربع $s', 'Q$s',
            fr: 'T$s', id: 'K$s', es: 'T$s', tr: '$s. Çeyrek', ms: 'Suku $s', ur: 'سہ ماہی $s',
            de: 'Q$s', pt: '$sº tri',
            it: 'T$s', nl: 'K$s', bs: 'K$s', sq: 'T$s', ru: '$s кв.', sw: 'Robo $s', ha: 'Kwata $s',
            af: 'K$s');
      case ReportPeriod.halfYearly:
        return s == 2 ? l.half2 : l.half1;
      case ReportPeriod.yearly:
        return '';
    }
  }
}
