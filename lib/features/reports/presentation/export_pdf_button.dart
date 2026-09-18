import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/features/reports/application/reports_controller.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

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
    return TextButton.icon(
      onPressed: _busy ? null : _export,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.picture_as_pdf_outlined, size: 16),
      label: Text(l.reportExportPdf),
    );
  }

  Future<void> _export() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _busy = true);
    try {
      final ReportResult report = ref.read(reportResultProvider);
      final ReportPeriod period = ref.read(selectedReportPeriodProvider);
      final int sub = ref.read(selectedReportSubProvider);
      final int year = ref.read(selectedYearProvider);
      final FinanceSummary s = report.summary;

      final String periodText = period == ReportPeriod.yearly
          ? '${_periodLabel(period, l)} · $year'
          : '${_periodLabel(period, l)} — ${_subLabel(period, sub, l, ar)} · $year';

      final ReportPdfData data = ReportPdfData(
        title: l.navReports,
        subtitle: periodText,
        generatedLabel: l.reportGeneratedOn(
            DateFormat('yyyy-MM-dd').format(DateTime.now())),
        kpis: <ReportRow>[
          ReportRow(l.kpiTotalIncome, MoneyFormatter.format(s.income)),
          ReportRow(l.kpiTotalExpenses, MoneyFormatter.format(s.expense)),
          ReportRow(l.kpiNetProfit, MoneyFormatter.format(s.net)),
          ReportRow(l.kpiSavingsRate, MoneyFormatter.percent(s.savingsRate)),
        ],
        incomeTitle: l.reportIncomeByCategory,
        income: _rows(report.incomeCategories, ar),
        expenseTitle: l.reportExpenseByCategory,
        expenses: _rows(report.expenseCategories, ar),
        emptyLabel: l.emptyTransactionsMessage,
        footer: 'DGOTIX Analytics · SmartBudget',
        isRtl: ar,
      );

      final pw.Font base = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
      final pw.Font bold =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
      final Uint8List bytes =
          await ReportPdfBuilder.build(data, base: base, bold: bold);
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

  List<ReportRow> _rows(List<CategoryTotal> totals, bool ar) => totals
      .map((CategoryTotal t) =>
          ReportRow(Catalog.label(t.category, ar: ar), MoneyFormatter.format(t.amount)))
      .toList();

  String _periodLabel(ReportPeriod p, AppLocalizations l) => switch (p) {
        ReportPeriod.monthly => l.periodMonthly,
        ReportPeriod.quarterly => l.periodQuarterly,
        ReportPeriod.halfYearly => l.periodHalfYearly,
        ReportPeriod.yearly => l.periodYearly,
      };

  String _subLabel(ReportPeriod p, int s, AppLocalizations l, bool ar) {
    switch (p) {
      case ReportPeriod.monthly:
        const List<String> arM = <String>[
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];
        const List<String> enM = <String>[
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
        return (ar ? arM : enM)[(s - 1).clamp(0, 11)];
      case ReportPeriod.quarterly:
        return ar ? 'الربع $s' : 'Q$s';
      case ReportPeriod.halfYearly:
        return s == 2 ? l.half2 : l.half1;
      case ReportPeriod.yearly:
        return '';
    }
  }
}
