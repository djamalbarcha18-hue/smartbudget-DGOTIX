import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Any character written in the Arabic script (Arabic, Persian, Urdu).
final RegExp _arabicScript = RegExp(r'[؀-ۿݐ-ݿﭐ-﻿]');

/// Drops invisible direction marks (LRM, RLM, embeddings, isolates), and
/// widens the gaps in Arabic-script text.
///
/// **The gap.** The PDF library shapes Arabic itself, and for some words it
/// emits the letters unshaped; where it does, the space that follows collapses
/// and two words print as one — "دار السلام" comes out "دارالسلام". It is the
/// library's bug, not ours: 3.13.1 is its newest release and still has it.
///
/// Doubling the space is the one remedy that works. A non-breaking space, a
/// zero-width space and a ZWNJ were each tried: the first changes nothing, and
/// the other two print as a missing-glyph box, because the bundled fonts have
/// no glyph for them.
///
/// The cost is that gaps between words the library sets correctly — most of
/// them — come out a little wide. That is the trade taken deliberately: a
/// slightly airy line is a blemish, two words run together is an error, and
/// which words are affected could not be predicted reliably enough to treat
/// them differently (see docs/REPORTS.md).
///
/// Latin, Cyrillic and CJK reports are untouched: the doubling applies only
/// where the text is in the Arabic script.
String pdfSafe(String s) {
  final String clean =
      s.replaceAll(RegExp('[\u200E\u200F\u202A-\u202E\u2066-\u2069]'), '');
  if (!_arabicScript.hasMatch(clean)) return clean;
  // Only single spaces, so running it twice changes nothing.
  return clean.replaceAll(RegExp('(?<! ) (?! )'), '  ');
}

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
    this.insightTitle,
    this.insight,
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

  /// The heading above the written commentary, and the commentary itself.
  /// Both null on a report without one — which is every report until the
  /// reader asks for it, and any report where the request did not come back.
  /// The rest of the page is identical either way.
  final String? insightTitle;
  final String? insight;

  bool get hasInsight =>
      (insight?.trim().isNotEmpty ?? false) &&
      (insightTitle?.trim().isNotEmpty ?? false);
}

/// Builds a branded (DGOTIX) A4 PDF for a report. The caller supplies an
/// Arabic-capable font (bundled Tajawal) so Arabic renders and shapes correctly.
abstract final class ReportPdfBuilder {
  // Const PdfColor(r,g,b) with normalized channels (0xFF1680F7 etc.).
  static const PdfColor _brand = PdfColor(0.08627, 0.50196, 0.96863);
  static const PdfColor _ink = PdfColor(0.05882, 0.09020, 0.16471);
  static const PdfColor _muted = PdfColor(0.39216, 0.45490, 0.54510);
  static const PdfColor _line = PdfColor(0.88627, 0.90980, 0.94118);

  /// The brand at 8% over white, worked out here rather than written as an
  /// alpha: a PDF fill does not blend, so an alpha colour prints solid.
  static const PdfColor _tint = PdfColor(0.92690, 0.96016, 0.99749);

  /// [base]/[bold] are Arabic-capable fonts supplied by the caller (bundled
  /// TTFs), so export works fully offline. [fallback] covers letters they
  /// lack (Turkish ğ ş İ in Tajawal).
  static Future<Uint8List> build(
    ReportPdfData data, {
    required pw.Font base,
    required pw.Font bold,
    List<pw.Font> fallback = const <pw.Font>[],
  }) async {
    final pw.Document doc = pw.Document(
      theme:
          pw.ThemeData.withFont(base: base, bold: bold, fontFallback: fallback),
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
          // Above the tables: what the figures mean comes before the figures
          // themselves, which is the order someone reads a report in.
          if (data.hasInsight) ...<pw.Widget>[
            _insight(data),
            pw.SizedBox(height: 16),
          ],
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
                    style: const pw.TextStyle(
                        color: _brand,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5)),
                pw.SizedBox(height: 2),
                pw.Text(pdfSafe(d.title),
                    style: const pw.TextStyle(
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 19)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: d.isRtl
                  ? pw.CrossAxisAlignment.start
                  : pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Text(pdfSafe(d.subtitle),
                    style: const pw.TextStyle(color: _muted, fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(pdfSafe(d.generatedLabel),
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
          pw.Text(pdfSafe(d.footer),
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
          pw.Text(pdfSafe(r.label),
              style: const pw.TextStyle(color: _muted, fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(pdfSafe(r.value),
              style: const pw.TextStyle(
                  color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  /// The written commentary, set as plain paragraphs inside a tinted block
  /// so it reads as commentary rather than as another table.
  static pw.Widget _insight(ReportPdfData d) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _tint,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(pdfSafe(d.insightTitle!),
              style: const pw.TextStyle(
                  color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          for (final String line in d.insight!.split('\n'))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(pdfSafe(line),
                  style: const pw.TextStyle(
                      color: _ink, fontSize: 9, lineSpacing: 2)),
            ),
        ],
      ),
    );
  }

  static pw.Widget _table(String title, List<ReportRow> rows, String empty) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Text(pdfSafe(title),
            style: const pw.TextStyle(
                color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        if (rows.isEmpty)
          pw.Text(pdfSafe(empty),
              style: const pw.TextStyle(color: _muted, fontSize: 10))
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
                    child: pw.Text(pdfSafe(r.label),
                        style: const pw.TextStyle(color: _ink, fontSize: 10)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(pdfSafe(r.value),
                      style: const pw.TextStyle(
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
