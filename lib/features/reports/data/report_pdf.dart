import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A single label/value line in the report.
class ReportRow {
  const ReportRow(this.label, this.value);
  final String label;
  final String value;
}

/// Everything the PDF needs, already localized & formatted by the caller so the
/// builder stays free of Flutter/context/l10n dependencies.
class ReportPdfData {
  const ReportPdfData({
    required this.title,
    required this.subtitle,
    required this.generatedLabel,
    required this.kpis,
    required this.incomeTitle,
    required this.income,
    required this.expenseTitle,
    required this.expenses,
    required this.emptyLabel,
    required this.footer,
    required this.isRtl,
  });

  final String title; // functional report title
  final String subtitle; // period · year
  final String generatedLabel; // "Generated: yyyy-MM-dd"
  final List<ReportRow> kpis;
  final String incomeTitle;
  final List<ReportRow> income;
  final String expenseTitle;
  final List<ReportRow> expenses;
  final String emptyLabel;
  final String footer;
  final bool isRtl;
}

/// Builds a branded (DGOTIX) A4 PDF for a report. The caller supplies an
/// Arabic-capable font (bundled Tajawal) so Arabic renders and shapes correctly.
abstract final class ReportPdfBuilder {
  // Const PdfColor(r,g,b) with normalized channels (0xFF1680F7 etc.).
  static const PdfColor _brand = PdfColor(0.08627, 0.50196, 0.96863);
  static const PdfColor _ink = PdfColor(0.05882, 0.09020, 0.16471);
  static const PdfColor _muted = PdfColor(0.39216, 0.45490, 0.54510);
  static const PdfColor _line = PdfColor(0.88627, 0.90980, 0.94118);

  /// [base]/[bold] are Arabic-capable fonts supplied by the caller (bundled
  /// TTFs), so export works fully offline.
  static Future<Uint8List> build(
    ReportPdfData data, {
    required pw.Font base,
    required pw.Font bold,
  }) async {
    final pw.Document doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: data.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        header: (pw.Context ctx) => _header(data),
        footer: (pw.Context ctx) => _footer(data, ctx),
        build: (pw.Context ctx) => <pw.Widget>[
          _kpis(data),
          pw.SizedBox(height: 20),
          _table(data.incomeTitle, data.income, data.emptyLabel),
          pw.SizedBox(height: 16),
          _table(data.expenseTitle, data.expenses, data.emptyLabel),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(ReportPdfData d) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text('DGOTIX',
                    style: pw.TextStyle(
                        color: _brand,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5)),
                pw.SizedBox(height: 2),
                pw.Text(d.title,
                    style: pw.TextStyle(
                        color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 19)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: d.isRtl
                  ? pw.CrossAxisAlignment.start
                  : pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Text(d.subtitle,
                    style: const pw.TextStyle(color: _muted, fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(d.generatedLabel,
                    style: const pw.TextStyle(color: _muted, fontSize: 9)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: _brand),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _footer(ReportPdfData d, pw.Context ctx) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(d.footer,
              style: const pw.TextStyle(color: _muted, fontSize: 8)),
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _kpis(ReportPdfData d) {
    return pw.Row(
      children: <pw.Widget>[
        for (int i = 0; i < d.kpis.length; i++) ...<pw.Widget>[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(child: _kpiBox(d.kpis[i])),
        ],
      ],
    );
  }

  static pw.Widget _kpiBox(ReportRow r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(r.label,
              style: const pw.TextStyle(color: _muted, fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(r.value,
              style: pw.TextStyle(
                  color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _table(String title, List<ReportRow> rows, String empty) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Text(title,
            style: pw.TextStyle(
                color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        if (rows.isEmpty)
          pw.Text(empty, style: const pw.TextStyle(color: _muted, fontSize: 10))
        else
          for (final ReportRow r in rows)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _line)),
              ),
              child: pw.Row(
                children: <pw.Widget>[
                  pw.Expanded(
                    child: pw.Text(r.label,
                        style: const pw.TextStyle(color: _ink, fontSize: 10)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(r.value,
                      style: pw.TextStyle(
                          color: _ink,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10)),
                ],
              ),
            ),
      ],
    );
  }
}
