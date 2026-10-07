import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';

void main() {
  test('money strings lose their direction mark in the PDF', () {
    final String shown = MoneyFormatter.format(const Money(34350000, 'QAR'));
    expect(shown.contains('\u200E'), isTrue); // kept on screen
    final String printed = pdfSafe(shown);
    expect(printed, 'ر.ق\u00A0343,500.00');
    expect(pdfSafe('\u2066abc\u2069 \u200Fد'), 'abc د');
    expect(pdfSafe('الطعام'), 'الطعام');
  });

  test('a report with Arabic and money values builds', () async {
    pw.Font font(String f) => pw.Font.ttf(
        ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync()));
    final Uint8List bytes = await ReportPdfBuilder.build(
      ReportPdfData(
        title: 'التحليلات والتقارير',
        subtitle: 'سنوي · 2026',
        generatedLabel: 'أُنشئ في 2026-09-29',
        kpis: <ReportRow>[
          ReportRow('إجمالي الدخل',
              MoneyFormatter.format(const Money(34350000, 'QAR'))),
        ],
        incomeTitle: 'الدخل حسب المصدر',
        income: <ReportRow>[
          ReportRow('راتب أساسي',
              MoneyFormatter.format(const Money(28800000, 'QAR'))),
        ],
        expenseTitle: 'المصروفات حسب الفئة',
        expenses: const <ReportRow>[],
        emptyLabel: 'لا توجد معاملات',
        footer: 'DGOTIX Analytics · SmartBudget',
        isRtl: true,
      ),
      base: font('Tajawal-Regular.ttf'),
      bold: font('Tajawal-Bold.ttf'),
    );
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
  });
}
