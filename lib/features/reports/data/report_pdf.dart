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

/// A line of the comparison table: this period against the one before it.
class ReportComparisonRow {
  const ReportComparisonRow(this.label, this.now, this.before, this.change,
      {this.up});

  final String label;
  final String now;
  final String before;

  /// Already formatted and signed by the caller ("+12.5%", "-3,000 DZD").
  final String change;

  /// true up, false down, null flat or not a direction worth colouring.
  /// Colour is never the only carrier: the sign is in [change] too, for a
  /// reader printing in black and white.
  final bool? up;
}

/// A small titled panel: the budget, the debts, the health score.
class ReportPanel {
  const ReportPanel({
    required this.title,
    required this.rows,
    this.meter,
    this.meterLabel,
    this.overMeter = false,
  });

  final String title;
  final List<ReportRow> rows;

  /// 0..1, drawn as a bar under the rows. Null leaves the panel plain.
  final double? meter;
  final String? meterLabel;

  /// Draws the meter in the warning colour: a budget already spent past its
  /// plan, for instance.
  final bool overMeter;
}

/// One month of the year chart.
class ReportTrendPoint {
  const ReportTrendPoint(this.label, this.income, this.expense, this.net);

  final String label;

  /// Minor units. The chart only ever compares them with each other, so no
  /// currency is needed.
  final int income;
  final int expense;

  /// Income minus expenses. Negative in a month that spent more than it
  /// took in, and the chart draws that below the line rather than hiding it.
  final int net;
}

/// A proportional bar in the "largest categories" strip.
class ReportBar {
  const ReportBar(this.label, this.value, this.ratio);

  final String label;
  final String value;

  /// 0..1 of the largest bar in the set.
  final double ratio;
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
    this.logoSvg,
    this.comparisonTitle,
    this.comparison = const <ReportComparisonRow>[],
    this.noComparisonLabel,
    this.panels = const <ReportPanel>[],
    this.trendTitle,
    this.trend = const <ReportTrendPoint>[],
    this.trendLegend = const <String>[],
    this.topTitle,
    this.top = const <ReportBar>[],
    this.excludedNote,
    this.risksTitle,
    this.risks = const <String>[],
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

  /// The DGOTIX mark, as SVG source. Null falls back to the wordmark set in
  /// type, so a report is never blocked on an asset that failed to load.
  final String? logoSvg;

  /// This period against the one before it. Empty when there is no earlier
  /// period; [noComparisonLabel] then says so rather than leaving a gap.
  final String? comparisonTitle;
  final List<ReportComparisonRow> comparison;
  final String? noComparisonLabel;

  /// Budget, debts, health — whichever the account has anything to say about.
  final List<ReportPanel> panels;

  /// The twelve months of the year, as grouped bars.
  final String? trendTitle;
  final List<ReportTrendPoint> trend;

  /// The three words under the title that say which colour is which:
  /// income, expenses, left over, in that order. Colour is never the only
  /// carrier — every figure is also in the tables.
  final List<String> trendLegend;

  /// The largest expense categories, as proportional bars.
  final String? topTitle;
  final List<ReportBar> top;

  /// One line stating what the totals could not include. Null on the
  /// ordinary report, where nothing was left out.
  final String? excludedNote;

  /// The standing risks worth printing, already written as sentences in the
  /// report's language. Empty on an account with none, and the block is
  /// then not drawn at all.
  final String? risksTitle;
  final List<String> risks;

  bool get hasRisks => risksTitle != null && risks.isNotEmpty;

  bool get hasInsight =>
      (insight?.trim().isNotEmpty ?? false) &&
      (insightTitle?.trim().isNotEmpty ?? false);

  bool get hasComparison =>
      comparisonTitle != null &&
      (comparison.isNotEmpty || noComparisonLabel != null);

  bool get hasTrend =>
      trendTitle != null &&
      trend.any((ReportTrendPoint p) => p.income > 0 || p.expense > 0);

  bool get hasTop => topTitle != null && top.isNotEmpty;
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

  /// Income green and expense red, dark enough to read on white and to stay
  /// legible when the page is printed in grey.
  static const PdfColor _up = PdfColor(0.08627, 0.53725, 0.32157);
  static const PdfColor _down = PdfColor(0.80392, 0.21569, 0.21569);

  /// The expense red at 7% over white, blended here because a PDF fill does
  /// not blend an alpha.
  static const PdfColor _warnTint = PdfColor(0.98627, 0.94510, 0.94510);

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
          if (data.excludedNote != null) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            _excluded(data.excludedNote!),
          ],
          pw.SizedBox(height: 18),
          // What the figures mean comes before the figures themselves, which
          // is the order a report is read in.
          if (data.hasInsight) ...<pw.Widget>[
            _insight(data),
            pw.SizedBox(height: 16),
          ],
          if (data.hasComparison) ...<pw.Widget>[
            _comparison(data),
            pw.SizedBox(height: 16),
          ],
          if (data.panels.isNotEmpty) ...<pw.Widget>[
            _panels(data),
            pw.SizedBox(height: 16),
          ],
          if (data.hasTrend) ...<pw.Widget>[
            _trend(data),
            pw.SizedBox(height: 16),
          ],
          if (data.hasTop) ...<pw.Widget>[
            _top(data),
            pw.SizedBox(height: 16),
          ],
          if (data.hasRisks) ...<pw.Widget>[
            _risks(data),
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
                _mark(d),
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

  /// The DGOTIX mark. The drawn logo when it was loaded, the wordmark set in
  /// type when it was not — an asset that failed to load must not cost the
  /// reader their report.
  static pw.Widget _mark(ReportPdfData d) {
    final String? svg = d.logoSvg;
    if (svg != null && svg.trim().isNotEmpty) {
      try {
        return pw.SvgImage(svg: svg, height: 17);
      } catch (_) {
        // A malformed asset falls through to the wordmark below.
      }
    }
    return pw.Text('DGOTIX',
        style: const pw.TextStyle(
            color: _brand,
            fontWeight: pw.FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.5));
  }

  /// What the totals could not include, stated under them rather than left
  /// for the reader to discover by adding the tables up themselves.
  static pw.Widget _excluded(String note) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _warnTint,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(pdfSafe(note),
          style: const pw.TextStyle(color: _down, fontSize: 8)),
    );
  }

  /// This period beside the one before it.
  static pw.Widget _comparison(ReportPdfData d) {
    if (d.comparison.isEmpty) {
      return _section(
        d.comparisonTitle!,
        pw.Text(pdfSafe(d.noComparisonLabel ?? ''),
            style: const pw.TextStyle(color: _muted, fontSize: 9)),
      );
    }
    return _section(
      d.comparisonTitle!,
      pw.Column(
        children: <pw.Widget>[
          for (int i = 0; i < d.comparison.length; i++)
            _comparisonRow(d.comparison[i], last: i == d.comparison.length - 1),
        ],
      ),
    );
  }

  static pw.Widget _comparisonRow(ReportComparisonRow r, {required bool last}) {
    final PdfColor tone = r.up == null ? _muted : (r.up! ? _up : _down);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: last
          ? null
          : const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
            ),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            flex: 4,
            child: pw.Text(pdfSafe(r.label),
                style: const pw.TextStyle(color: _ink, fontSize: 9)),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(pdfSafe(r.now),
                style: const pw.TextStyle(
                    color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(pdfSafe(r.before),
                style: const pw.TextStyle(color: _muted, fontSize: 9)),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(pdfSafe(r.change),
                style: pw.TextStyle(
                    color: tone, fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  /// Budget, debts and health side by side.
  static pw.Widget _panels(ReportPdfData d) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        for (int i = 0; i < d.panels.length; i++) ...<pw.Widget>[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(child: _panel(d.panels[i])),
        ],
      ],
    );
  }

  static pw.Widget _panel(ReportPanel p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(pdfSafe(p.title),
              style: const pw.TextStyle(
                  color: _muted, fontSize: 8, letterSpacing: 0.3)),
          pw.SizedBox(height: 6),
          for (final ReportRow r in p.rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Expanded(
                    child: pw.Text(pdfSafe(r.label),
                        style: const pw.TextStyle(color: _muted, fontSize: 8)),
                  ),
                  pw.Text(pdfSafe(r.value),
                      style: const pw.TextStyle(
                          color: _ink,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9)),
                ],
              ),
            ),
          if (p.meter != null) ...<pw.Widget>[
            pw.SizedBox(height: 5),
            _meter(p.meter!, over: p.overMeter),
            if (p.meterLabel != null) ...<pw.Widget>[
              pw.SizedBox(height: 3),
              pw.Text(pdfSafe(p.meterLabel!),
                  style: const pw.TextStyle(color: _muted, fontSize: 7)),
            ],
          ],
        ],
      ),
    );
  }

  /// A filled bar, clamped so a budget spent twice over still fits the panel.
  ///
  /// Built from two flexed halves rather than a fraction of the width: the
  /// PDF library has no fractional box, and integer flex divides exactly.
  /// The library mirrors a row's children on a right-to-left page, so the
  /// fill starts at the right there without anything being reversed here.
  static pw.Widget _meter(double ratio, {bool over = false}) {
    final double v = ratio.isNaN ? 0 : ratio.clamp(0.0, 1.0);
    final int filled = (v * 1000).round();
    final List<pw.Widget> parts = <pw.Widget>[
      if (filled > 0)
        pw.Expanded(
          flex: filled,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: over ? _down : _brand,
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
        ),
      if (filled < 1000) pw.Expanded(flex: 1000 - filled, child: pw.SizedBox()),
    ];
    return pw.Container(
      height: 5,
      decoration: pw.BoxDecoration(
        color: _line,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(children: parts),
    );
  }

  /// Twelve months, income and expense as paired columns.
  ///
  /// Drawn rather than charted: the chart widgets place their own axes and
  /// do not mirror for a right-to-left page. Drawn from rows, the library
  /// mirrors it for us, so January sits at the right in Arabic and at the
  /// left in English with one list and no special case.
  static pw.Widget _trend(ReportPdfData d) {
    const double height = 52;
    const double deficit = 13;

    final List<ReportTrendPoint> points = d.trend;
    final int peak = points.fold<int>(
        1,
        (int m, ReportTrendPoint p) => <int>[
              m,
              p.income,
              p.expense,
              p.net.abs()
            ].reduce((int a, int b) => a > b ? a : b));

    // A month that spent more than it took in: its bar hangs below the line.
    final bool anyDeficit = points.any((ReportTrendPoint p) => p.net < 0);

    double up(int v) => v <= 0 ? 0 : (v / peak) * height;
    double down(int v) => v >= 0 ? 0 : (v.abs() / peak) * height;

    pw.Widget bar(double h, PdfColor colour) =>
        pw.Container(width: 4.5, height: h < 0.6 ? 0.6 : h, color: colour);

    return _section(
      d.trendTitle!,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          if (d.trendLegend.length == 3) ...<pw.Widget>[
            _legend(d.trendLegend),
            pw.SizedBox(height: 6),
          ],
          pw.SizedBox(
            height: height,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                for (final ReportTrendPoint p in points)
                  pw.Expanded(
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: <pw.Widget>[
                        bar(up(p.income), _up),
                        pw.SizedBox(width: 1.5),
                        bar(up(p.expense), _down),
                        pw.SizedBox(width: 1.5),
                        bar(up(p.net), _brand),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(height: 0.5, color: _line),
          if (anyDeficit)
            pw.SizedBox(
              height: deficit,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  for (final ReportTrendPoint p in points)
                    pw.Expanded(
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          // The group above is 16.5 wide (three 4.5 bars,
                          // two 1.5 gaps) and centred; this spacer makes
                          // this row the same width, so the deficit hangs
                          // exactly under its month's left-over bar.
                          pw.SizedBox(width: 12),
                          if (p.net < 0)
                            pw.Container(
                              width: 4.5,
                              height: down(p.net).clamp(0.6, deficit),
                              color: _brand,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: <pw.Widget>[
              for (final ReportTrendPoint p in points)
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(pdfSafe(p.label),
                        style: const pw.TextStyle(color: _muted, fontSize: 6)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Income, expenses, left over — the three words that say which colour is
  /// which, in the report's own language.
  static pw.Widget _legend(List<String> labels) {
    const List<PdfColor> colours = <PdfColor>[_up, _down, _brand];
    return pw.Row(
      children: <pw.Widget>[
        for (int i = 0; i < 3; i++) ...<pw.Widget>[
          if (i > 0) pw.SizedBox(width: 12),
          pw.Container(width: 6, height: 6, color: colours[i]),
          pw.SizedBox(width: 4),
          pw.Text(pdfSafe(labels[i]),
              style: const pw.TextStyle(color: _muted, fontSize: 7)),
        ],
      ],
    );
  }

  /// The largest expense categories as proportional bars.
  static pw.Widget _top(ReportPdfData d) {
    return _section(
      d.topTitle!,
      pw.Column(
        children: <pw.Widget>[
          for (final ReportBar b in d.top)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: <pw.Widget>[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Expanded(
                        child: pw.Text(pdfSafe(b.label),
                            style:
                                const pw.TextStyle(color: _ink, fontSize: 8)),
                      ),
                      pw.Text(pdfSafe(b.value),
                          style: const pw.TextStyle(
                              color: _ink,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  // Spending, so red — the same rule the chart follows.
                  _meter(b.ratio, over: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// What the figures warn about, one sentence each.
  ///
  /// These come from the health engine, which already works them out for its
  /// own screen; the report states them rather than computing them twice.
  static pw.Widget _risks(ReportPdfData d) {
    return _section(
      d.risksTitle!,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          for (final String risk in d.risks)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(
                      width: 3,
                      height: 9,
                      margin: const pw.EdgeInsets.only(top: 1),
                      color: _down),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(pdfSafe(risk),
                        style: const pw.TextStyle(color: _ink, fontSize: 9)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A titled block, so every section on the page carries the same heading.
  static pw.Widget _section(String title, pw.Widget child) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Text(pdfSafe(title),
            style: const pw.TextStyle(
                color: _ink, fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        child,
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
